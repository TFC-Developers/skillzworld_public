#include "include/global"

new const g_sFactFile[] = "sw_message_facts.txt"

new Array:g_MessageList
new g_iMessageCount


public plugin_init()
{
	RegisterPlugin()
	g_MessageList = ArrayCreate(MAX_HUDMSG_LEN)
	ReadFactFile()


}

public plugin_end()
{
	ArrayDestroy(g_MessageList)
}

ReadFactFile()
{
	new sFile[128]; BuildAMXFilePath(g_sFactFile, sFile, charsmax(sFile), "amxx_configsdir")
	new iFileHandle = fopen(sFile, "rt")
	if (!iFileHandle)
	{
		WarningLog(FM_FOPEN_WARNING, sFile)
		return 0	
	}

	new sData[MAX_HUDMSG_LEN]
	while (!feof(iFileHandle))
	{
		fgets(iFileHandle, sData, charsmax(sData))
		trim(sData)
					
		if (!fm_Comment(sData))
		{
			ArrayPushString(g_MessageList, sData)
			g_iMessageCount++
		}		
	}
	fclose(iFileHandle)
	log_amx("Loaded %d facts from %s", g_iMessageCount, sFile)

	return g_iMessageCount
}

public fwd_ScreenMessage(sBuffer[], iSize)
{
	if (!g_iMessageCount) {
		// Error handling needs to be added to FM_MESSAGE.amxx
		formatex(sBuffer, iSize, "")
		return PLUGIN_HANDLED	
	}
	new iSize = ArraySize(g_MessageList);
	if (iSize == 0) return PLUGIN_HANDLED;
	
	new iRand = random(g_iMessageCount);
	ArrayGetString(g_MessageList, iRand, sBuffer, iSize);
	ArrayDeleteItem(g_MessageList, iRand);
	return PLUGIN_HANDLED
}
