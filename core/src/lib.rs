#![warn(clippy::all)]

use std::collections::HashMap;
use std::ffi::CStr;
use std::net::{IpAddr, SocketAddr};
use std::os::raw::c_char;
use std::sync::Mutex;

use once_cell::sync::Lazy;
use tokio::io::copy_bidirectional;
use tokio::net::{TcpListener, TcpStream};
use tokio::runtime::Runtime;
use tokio::task::JoinHandle;

mod error;

use error::Error;

static RT: Lazy<Runtime> = Lazy::new(|| Runtime::new().unwrap());

static AVAILABLE_RULE_IDS: Lazy<Mutex<Vec<i8>>> = Lazy::new(|| {
    let mut pool = Vec::with_capacity(128);
    pool.extend(0..=127);
    Mutex::new(pool)
});

static RUNNING_RULES: Lazy<Mutex<HashMap<i8, ForwardRuleHandler>>> =
    Lazy::new(|| Mutex::new(HashMap::with_capacity(128)));

/// Get a new rule ID.
#[inline]
fn get_new_rule_id() -> Option<i8> {
    AVAILABLE_RULE_IDS.lock().unwrap().pop()
}

/// Make a rule ID available again.
#[inline]
fn release_rule_id(rule_id: i8) {
    AVAILABLE_RULE_IDS.lock().unwrap().push(rule_id);
}

enum ForwardRuleHandler {
    Single(JoinHandle<()>),
    Multiple(Vec<JoinHandle<()>>),
}
impl ForwardRuleHandler {
    pub fn single(handler: JoinHandle<()>) -> Self {
        Self::Single(handler)
    }

    pub fn multiple(handlers: Vec<JoinHandle<()>>) -> Self {
        Self::Multiple(handlers)
    }

    pub fn abort(self) {
        match self {
            Self::Single(handler) => {
                handler.abort();
            }

            Self::Multiple(handlers) => {
                for handler in handlers {
                    handler.abort();
                }
            }
        }
    }
}

/// Check if an IP address is valid.
#[no_mangle]
#[allow(clippy::not_unsafe_ptr_arg_deref)]
pub extern "C" fn ipf_check_ip_is_valid(ip_c_string: *const c_char) -> bool {
    let ip_str = unsafe {
        if let Ok(ip_str) = CStr::from_ptr(ip_c_string).to_str() {
            ip_str
        } else {
            return false;
        }
    };

    ip_str.parse::<IpAddr>().is_ok()
}

/// Forward a TCP port to another IP address.
#[no_mangle]
#[allow(clippy::not_unsafe_ptr_arg_deref)]
pub extern "C" fn ipf_forward(
    ip_c_string: *const c_char,
    remote_port: u16,
    local_port: u16,
    allow_lan: bool,
) -> i8 {
    if let Some(rule_id) = get_new_rule_id() {
        let ip_str = unsafe {
            match CStr::from_ptr(ip_c_string).to_str() {
                Ok(ip_str) => ip_str,
                Err(_) => return Error::InvalidString as i8,
            }
        };
        let ip: IpAddr = match ip_str.parse() {
            Ok(ip) => ip,
            Err(_) => return Error::InvalidIpAddr as i8,
        };

        let join_handler = RT.spawn(async move {
            let listener = TcpListener::bind(SocketAddr::new(
                if allow_lan { "0.0.0.0" } else { "127.0.0.1" }
                    .parse()
                    .unwrap(),
                local_port,
            ))
            .await
            .unwrap();

            loop {
                if let Ok((mut ingress, _)) = listener.accept().await {
                    if let Ok(mut egress) =
                        TcpStream::connect(SocketAddr::new(ip, remote_port)).await
                    {
                        RT.spawn(async move {
                            _ = copy_bidirectional(&mut ingress, &mut egress).await;
                        });
                    }
                }
            }
        });

        RUNNING_RULES
            .lock()
            .unwrap()
            .insert(rule_id, ForwardRuleHandler::single(join_handler));

        rule_id
    } else {
        Error::TooManyRules as i8
    }
}

/// Forward a range of TCP ports to another IP address.
#[no_mangle]
#[allow(clippy::not_unsafe_ptr_arg_deref)]
pub extern "C" fn ipf_forward_range(
    ip_c_string: *const c_char,
    remote_port_start: u16,
    remote_port_end: u16,
    local_port_start: u16,
    allow_lan: bool,
) -> i8 {
    if u16::MAX - (remote_port_end - remote_port_start) < local_port_start {
        return Error::InvalidLocalPortStart as i8;
    }

    if let Some(rule_id) = get_new_rule_id() {
        let ip_str = unsafe {
            match CStr::from_ptr(ip_c_string).to_str() {
                Ok(ip_str) => ip_str,
                Err(_) => return Error::InvalidString as i8,
            }
        };
        let ip: IpAddr = match ip_str.parse() {
            Ok(ip) => ip,
            Err(_) => return Error::InvalidIpAddr as i8,
        };

        let join_handlers = (remote_port_start..=remote_port_end)
            .enumerate()
            .map(move |(index, remote_port)| {
                let local_port = local_port_start + index as u16;
                RT.spawn(async move {
                    let listener = TcpListener::bind(SocketAddr::new(
                        if allow_lan { "0.0.0.0" } else { "127.0.0.1" }
                            .parse()
                            .unwrap(),
                        local_port,
                    ))
                    .await
                    .unwrap();

                    loop {
                        if let Ok((mut ingress, _)) = listener.accept().await {
                            if let Ok(mut egress) =
                                TcpStream::connect(SocketAddr::new(ip, remote_port)).await
                            {
                                RT.spawn(async move {
                                    _ = copy_bidirectional(&mut ingress, &mut egress).await;
                                });
                            }
                        }
                    }
                })
            })
            .collect();

        RUNNING_RULES
            .lock()
            .unwrap()
            .insert(rule_id, ForwardRuleHandler::multiple(join_handlers));

        rule_id
    } else {
        Error::TooManyRules as i8
    }
}

/// Cancel a forward rule.
#[no_mangle]
pub extern "C" fn ipf_cancel_forward(forward_rule_id: i8) -> i8 {
    if let Some(join_handler) = RUNNING_RULES.lock().unwrap().remove(&forward_rule_id) {
        release_rule_id(forward_rule_id);
        join_handler.abort();
        forward_rule_id
    } else {
        Error::InvalidRuleId as i8
    }
}
