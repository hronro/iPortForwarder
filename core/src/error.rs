use std::io;

/// Errors returned by the library.
#[repr(i8)]
pub enum Error {
    /// Unknown error.
    Unknown = -1,

    // Library errors, from -10 to -50.
    /// Invalid C format string.
    InvalidString = -10,

    /// The IP address is invalid.
    InvalidIpAddr = -11,

    /// At most 128 rules are allowed.
    TooManyRules = -12,

    /// The rule ID is invalid.
    InvalidRuleId = -13,

    /// The local port start is invalid,
    /// which will make the local port end greater than 65535.
    InvalidLocalPortStart = -14,

    /// The remote port end is invalid.
    InvalidRemotePortEnd = -15,

    /// The error handler has already been registered.
    HandlerAlreadyRegistered = -16,

    // OS errors, from -51 to -127.
    /// Permission denied.
    PermissionDenied = -51,

    /// Address already in use.
    AddrInUse = -52,

    /// Address already exists.
    AlreadyExists = -53,

    /// An operation could not be completed, because it failed
    /// to allocate enough memory.
    OutOfMemory = -54,

    /// Too many open files.
    TooManyOpenFiles = -55,
}
impl From<io::Error> for Error {
    fn from(io_error: io::Error) -> Self {
        match io_error.kind() {
            io::ErrorKind::PermissionDenied => Self::PermissionDenied,

            io::ErrorKind::AddrInUse => Self::AddrInUse,

            io::ErrorKind::AlreadyExists => Self::AlreadyExists,

            io::ErrorKind::OutOfMemory => Self::OutOfMemory,

            _ if io_error.raw_os_error() == Some(24) => Self::TooManyOpenFiles,

            _ => Self::Unknown,
        }
    }
}
