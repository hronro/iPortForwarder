_Bool ipf_check_ip_is_valid(char *ip);

signed char ipf_forward(char *ip, unsigned short int port, _Bool allow_lan);

signed char ipf_cancel_forward(signed char forward_rule_id);
