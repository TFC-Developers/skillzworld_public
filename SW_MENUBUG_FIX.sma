/* copied from ben / watch out of the fm repo on 26/05/2023 */
#include "include/global"

new g_iMenuMsgId

public plugin_init()
{
	RegisterPlugin()
	g_iMenuMsgId = get_user_msgid("ShowMenu")
}

public client_putinserver(id)
{
	set_task(1.0, "ClearMenu", id) // Delay is required
}
	
public ClearMenu(id)
{	
	if (is_user_connected(id))
	{
		message_begin(MSG_ONE, g_iMenuMsgId, { 0, 0, 0 }, id) 
		write_short(0)
		write_char(0)
		write_byte(0)
		write_string("")
		message_end()
	}
}