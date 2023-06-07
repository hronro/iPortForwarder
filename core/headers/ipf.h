/** Check if an IP address is valid. */
_Bool ipf_check_ip_is_valid(char *ip);

/** Forward a TCP port to another IP address. */
signed char ipf_forward(
	char *ip,
	unsigned short int remote_port,
	unsigned short int local_port,
	_Bool allow_lan
);

/** Forward a range of TCP ports to another IP address. */
signed char ipf_forward_range(
	char *ip,
	unsigned short int remote_port_start,
	unsigned short int remote_port_end,
	unsigned short int local_port_start,
	_Bool allow_lan
);

/** Cancel a forward rule. */
signed char ipf_cancel_forward(signed char forward_rule_id);

/** Register error handler. */
signed char ipf_register_error_handler(signed char (*handler)(signed char));
