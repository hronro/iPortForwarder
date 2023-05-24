use std::ffi::CStr;
use std::net::{IpAddr, SocketAddr};
use std::os::raw::c_char;

use once_cell::sync::Lazy;
use tokio::io::copy_bidirectional;
use tokio::net::{TcpListener, TcpStream};
use tokio::runtime::Runtime;

static RT: Lazy<Runtime> = Lazy::new(|| Runtime::new().unwrap());

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

#[no_mangle]
#[allow(clippy::not_unsafe_ptr_arg_deref)]
pub extern "C" fn ipf_forward(ip_c_string: *const c_char, port: u16, allow_lan: bool) {
    let ip_str = unsafe { CStr::from_ptr(ip_c_string).to_str().unwrap() };
    let ip: IpAddr = ip_str.parse().unwrap();

    RT.spawn(async move {
        let listener = TcpListener::bind(SocketAddr::new(
            if allow_lan { "0.0.0.0" } else { "127.0.0.1" }
                .parse()
                .unwrap(),
            port,
        ))
        .await
        .unwrap();

        loop {
            if let Ok((mut ingress, _)) = listener.accept().await {
                if let Ok(mut egress) = TcpStream::connect(SocketAddr::new(ip, port)).await {
                    RT.spawn(async move {
                        _ = copy_bidirectional(&mut ingress, &mut egress).await;
                    });
                }
            }
        }
    });
}
