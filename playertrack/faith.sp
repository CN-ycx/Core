public void SetClientFaith(int client, int faith)
{
	if(!g_eClient[client][bLoaded])
	{
		PrintToChat(client, "%s  很抱歉,你的数据尚未加载完毕", PLUGIN_PREFIX);
		return;
	}
	
	g_eClient[client][iFaith] = faith;
	
	char m_szQuery[256];
	Format(m_szQuery, 256, "UPDATE `playertrack_player` SET faith = '%d' WHERE id = '%d'", faith, g_eClient[client][iPlayerId]);
	SQL_TQuery(g_hDB_csgo, SQLCallback_SetFaith, m_szQuery, GetClientUserId(client));
}

public void ShowFaithFirstMenuToClient(int client)
{
	Handle menu = CreateMenu(FaithFirstMenuHandler);
	SetMenuTitle(menu, "[Planeptune]   Faith - Select\n　");
	
	AddMenuItem(menu, "", "目前系统检测到你的Faith为空[输入!fhelp了解更多]", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "选择1个Faith以获得Buff[暂时不能更换]", ITEMDRAW_DISABLED);
	
	char m_szItem[256];

	Format(m_szItem, 256, "[%s - %s] - Buff: 速度  Guardian: 猫灵", szFaith_NATION[PURPLE], szFaith_NAME[PURPLE]);
	AddMenuItem(menu, "purple", m_szItem);
	
	Format(m_szItem, 256, "[%s - %s] - Buff: 暴击  Guardian: 曼妥思", szFaith_NATION[BLACK], szFaith_NAME[BLACK]);
	AddMenuItem(menu, "black", m_szItem);
	
	Format(m_szItem, 256, "[%s - %s] - Buff: 伤害  Guardian: 色拉", szFaith_NATION[WHITE], szFaith_NAME[WHITE]);
	AddMenuItem(menu, "white", m_szItem);

	Format(m_szItem, 256, "[%s - %s] - Buff: 闪避  Guardian: 基佬桐", szFaith_NATION[GREEN], szFaith_NAME[GREEN]);
	AddMenuItem(menu, "green", m_szItem);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int FaithFirstMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "purple"))
			ConfirmSelect(client, PURPLE);
		else if(StrEqual(info, "black"))
			ConfirmSelect(client, BLACK);
		else if(StrEqual(info, "white"))
			ConfirmSelect(client, WHITE);
		else if(StrEqual(info, "green"))
			ConfirmSelect(client, GREEN);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public int FaithHelpMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	
}

public void ConfirmSelect(int client, int faith)
{
	Handle menu = CreateMenu(FaithConfirmMenuHandler);
	SetMenuTitle(menu, "[Planeptune]   Faith - Confirm\n　");
	
	char m_szItem[128];
	if(faith == 1)
	{
		Format(m_szItem, 128, "你选择的是 [%s - %s]", szFaith_NATION[faith], szFaith_NAME[faith]);
		AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Buff类型 [速度]", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Guardian [猫灵]", ITEMDRAW_DISABLED);
	}
	if(faith == 2)
	{
		Format(m_szItem, 128, "你选择的是 [%s - %s]", szFaith_NATION[faith], szFaith_NAME[faith]);
		AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Buff类型 [暴击]", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Guardian [MTS.]", ITEMDRAW_DISABLED);
	}
	if(faith == 3)
	{
		Format(m_szItem, 128, "你选择的是 [%s - %s]", szFaith_NATION[faith], szFaith_NAME[faith]);
		AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Buff类型 [伤害]", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Guardian [色拉]", ITEMDRAW_DISABLED);
	}
	if(faith == 4)
	{
		Format(m_szItem, 128, "你选择的是 [%s - %s]", szFaith_NATION[faith], szFaith_NAME[faith]);
		AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Buff类型 [闪避]", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "Guardian [桐子]", ITEMDRAW_DISABLED);
	}

	Format(m_szItem, 128, "Faith不能更改, 你确定你的选择吗:)\n　");
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 128, "%d", faith);
	AddMenuItem(menu, m_szItem, "我确定");
	AddMenuItem(menu, "0", "我拒绝");

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public int FaithConfirmMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		int faith = StringToInt(info);
		
		if(faith > 0)
			SetClientFaith(client, faith);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		ShowFaithFirstMenuToClient(client);
	}
}

public void ShowFaithMainMenuToClient(int client)
{
	if(!(0 < g_eClient[client][iFaith] <= FAITH_COUNTS))
	{
		ShowFaithFirstMenuToClient(client);
		return;
	}
	
	Handle menu = CreateMenu(FaithMainMenuHandler);
	SetMenuTitle(menu, "[Planeptune]   Faith - Main\n \n当前归属: %s - %s\n当前Share: %d\n　", szFaith_NATION[g_eClient[client][iFaith]], szFaith_NAME[g_eClient[client][iFaith]], g_eClient[client][iShare]);

	AddMenuItem(menu, "fhelp", "关于Faith系统说明");
	AddMenuItem(menu, "share", "查看当前Share数据");
	AddMenuItem(menu, "fbuff", "查看各个Faith的Buff");
	AddMenuItem(menu, "guild", "承接任务以增加Sahre");
	AddMenuItem(menu, "rank", "查看你的Share排行");

	if(g_eClient[client][iBuff] <= 0)
		AddMenuItem(menu, "reset", "初次设置副Buff");
	else
		AddMenuItem(menu, "reset", "重新选择副Buff");
	
	AddMenuItem(menu, "charge", "充值信仰[已关闭]", ITEMDRAW_DISABLED);

	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int FaithMainMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "fhelp"))
			Command_FHelp(client, 0);
		else if(StrEqual(info, "share"))
			ShowAllFaithShareToClient(client);
		else if(StrEqual(info, "fbuff"))
			ShowAllFaithBuffToClient(client);
		else if(StrEqual(info, "guild"))
			FakeClientCommandEx(client, "sm_guild");
		else if(StrEqual(info, "reset"))
		{
			if(g_eClient[client][iBuff] <= 0)
				CheckClientBuff(client);
			else
				FakeClientCommandEx(client, "sm_freset");
		}		
		else if(StrEqual(info, "charge"))
			FakeClientCommandEx(client, "sm_fcharge");
		else if(StrEqual(info, "rank"))
			ShowFaithShareRankToClient(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

public void ShowAllFaithShareToClient(int client)
{
	Handle menu = CreateMenu(ShowAllFaithShareMenuHandler);
	SetMenuTitle(menu, "[Planeptune]   Faith -  查看各个Faith的Share值\n　");

	float share[5];
	share[ALLSHARE] = float(g_Share[PURPLE]+g_Share[BLACK]+g_Share[WHITE]+g_Share[GREEN]);
	share[PURPLE] = (float(g_Share[PURPLE])/share[ALLSHARE])*100;
	share[BLACK] = (float(g_Share[BLACK])/share[ALLSHARE])*100;
	share[WHITE] = (float(g_Share[WHITE])/share[ALLSHARE])*100;
	share[GREEN] = (float(g_Share[GREEN])/share[ALLSHARE])*100;
	
	char m_szItem[256];

	Format(m_szItem, 256, "[Purple] - Share %d [%.2f%% of %d]", g_Share[PURPLE], share[PURPLE], RoundToFloor(share[ALLSHARE]));
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 256, "[Black] - Share %d [%.2f%% of %d]", g_Share[BLACK], share[BLACK], RoundToFloor(share[ALLSHARE]));
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 256, "[White] - Share %d [%.2f%% of %d]", g_Share[WHITE], share[WHITE], RoundToFloor(share[ALLSHARE]));
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 256, "[Green] - Share %d [%.2f%% of %d]", g_Share[GREEN], share[GREEN], RoundToFloor(share[ALLSHARE]));
	AddMenuItem(menu, "", m_szItem, ITEMDRAW_DISABLED);
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 60);
	
	ShowFaithOfferToClient(client);
}

public int ShowAllFaithShareMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	
}

public void ShowAllFaithBuffToClient(int client)
{
	Handle menu = CreateMenu(ShowAllFaithBuffMenuHandler);
	SetMenuTitle(menu, "[Planeptune]   Faith -  查看各个Faith的Buff\n　");
	
	char m_szItem[256];

	Format(m_szItem, 256, "[%s - %s] - Buff: 速度", szFaith_NATION[PURPLE], szFaith_NAME[PURPLE]);
	AddMenuItem(menu, "purple", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 256, "[%s - %s] - Buff: 暴击", szFaith_NATION[BLACK], szFaith_NAME[BLACK]);
	AddMenuItem(menu, "black", m_szItem, ITEMDRAW_DISABLED);
	
	Format(m_szItem, 256, "[%s - %s] - Buff: 伤害", szFaith_NATION[WHITE], szFaith_NAME[WHITE]);
	AddMenuItem(menu, "white", m_szItem, ITEMDRAW_DISABLED);

	Format(m_szItem, 256, "[%s - %s] - Buff: 闪避", szFaith_NATION[GREEN], szFaith_NAME[GREEN]);
	AddMenuItem(menu, "green", m_szItem, ITEMDRAW_DISABLED);

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int ShowAllFaithBuffMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		ShowFaithMainMenuToClient(client);
	}
}

public void ShowFaithOfferToClient(int client)
{
	float vol = (float(g_eClient[client][iShare])/float(g_Share[g_eClient[client][iFaith]]))*100;
	PrintToChat(client, "[%s]  你个人贡献的Share为\x0C%d\x01点[%.2f%% of %d - %s]", szFaith_CNAME[g_eClient[client][iFaith]], g_eClient[client][iShare], vol, g_Share[g_eClient[client][iFaith]], szFaith_CNATION[g_eClient[client][iFaith]]);
}

public void ShowFaithShareRankToClient(int client)
{
	char sQuery[512];
	Format(sQuery, 512, "SELECT `name`, `share` FROM `playertrack_player` WHERE `faith` = '%d' ORDER BY `share` DESC LIMIT 50;", g_eClient[client][iFaith]);
	SQL_TQuery(g_hDB_csgo, SQLCallback_FaithShareRank, sQuery, g_eClient[client][iUserId]);
}

void ShareRankToMenu(int client, Handle pack)
{
	char m_szItem[256], sName[128];
	Handle hMenu = CreateMenu(ShareRankMenuHandler);

	Format(m_szItem, 256, "[Planeptune]   Faith Share Rank - %s \n　", szFaith_NAME[g_eClient[client][iFaith]]);
	SetMenuTitle(hMenu, m_szItem);

	SetMenuExitButton(hMenu, true);
	SetMenuExitBackButton(hMenu, false);

	ResetPack(pack);
	
	int iCount = ReadPackCell(pack);

	for(int i = 0; i < iCount; ++i)
	{
		ReadPackString(pack, sName, 128);
		int ishare = ReadPackCell(pack);
		float vol = (float(ishare)/float(g_Share[g_eClient[client][iFaith]]))*100;
		Format(m_szItem, 128, "#%d   %s  %d[%.2f%% of %d - %s]", i+1, sName, ishare, vol, g_Share[g_eClient[client][iFaith]], szFaith_NATION[g_eClient[client][iFaith]]);
		AddMenuItem(hMenu, "", m_szItem, ITEMDRAW_DISABLED);
	}

	CloseHandle(pack);
	DisplayMenu(hMenu, client, 60);
}

public int ShareRankMenuHandler(Handle menu, MenuAction action, int client, int itemNum)
{

}

void CheckClientBuff(int client)
{
	if(g_eClient[client][iFaith] <= 0 || g_eClient[client][iBuff] > 0)
		return;

	Handle menu = CreateMenu(ShowSecondBuffMenuHandler);
	SetMenuTitle(menu, "[Planeptune]   Faith -  Second Buff\n　");
	
	AddMenuItem(menu, "", "系统侦测到当前你未设置副Buff", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "副Buff加成为定值,不受Faith和Share影响", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "副Buff只有在你的Share大于1000点时才会激活", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "修改副Buff每次需要5000Credits", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "你现在要设置吗?", ITEMDRAW_DISABLED);

	AddMenuItem(menu, "yes", "设置");
	
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int ShowSecondBuffMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		if(StrEqual(info, "yes"))
			ShowSecondBuffToClient(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void ShowSecondBuffToClient(int client)
{
	Handle menu = CreateMenu(SelectSecondBuffMenuHandler);
	SetMenuTitle(menu, "[Planeptune]   Faith -  Second Buff\n　");
	
	AddMenuItem(menu, "1", "射速 [提高除了匕首和手雷之外枪械的射速]");
	AddMenuItem(menu, "2", "嗜血 [造成40点伤害(ZE为800)后恢复2点HP]");
	AddMenuItem(menu, "3", "生命 [提升当前血量和血量上限8%的生命值]");
	AddMenuItem(menu, "4", "护甲 [几率获得重甲护甲低于10自动补到10]");
	AddMenuItem(menu, "5", "基因 [提升!10%跳跃高度和跳跃距离的能力]");
	AddMenuItem(menu, "6", "子弹 [每射击一定次数会给主弹夹补充子弹]");
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 0);
}

public int SelectSecondBuffMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		ConfirmSecondBuff(client, StringToInt(info));
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if(action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		CheckClientBuff(client);
	}
}

void ConfirmSecondBuff(int client, int buff)
{
	Handle menu = CreateMenu(ConfirmSecondBuffMenuHandler);
	SetMenuTitle(menu, "[Planeptune]   Faith -  Second Buff\n　");
	
	if(buff == 1)
	{
		AddMenuItem(menu, "", "你选择的Buff是: 射速", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "提升除了手雷/匕首之外所有武器5%的射速", ITEMDRAW_DISABLED);
	}
	else if(buff == 2)
	{
		AddMenuItem(menu, "", "你选择的Buff是: 嗜血", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "你每造成30点(ZE模式为500点)伤害就能恢复2点HP", ITEMDRAW_DISABLED);
	}
	else if(buff == 3)
	{
		AddMenuItem(menu, "", "你选择的Buff是: 生命", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "出生时提升血量和血量上限10%", ITEMDRAW_DISABLED);
	}
	else if(buff == 4)
	{
		AddMenuItem(menu, "", "你选择的Buff是: 护甲", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "出生时有8%几率获得重甲|护甲低于10自动补到10", ITEMDRAW_DISABLED);
	}
	else if(buff == 5)
	{
		AddMenuItem(menu, "", "你选择的Buff是: 基因", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "跳跃高度|跳跃距离都提升8%(不受重力影响)", ITEMDRAW_DISABLED);
	}
	else if(buff == 6)
	{
		AddMenuItem(menu, "", "你选择的Buff是: 子弹", ITEMDRAW_DISABLED);
		AddMenuItem(menu, "", "你每射出10发(ZE为30)子弹将会往你主弹夹填充2发子弹", ITEMDRAW_DISABLED);
	}

	AddMenuItem(menu, "", "修改子Buff每次需要5000Credits", ITEMDRAW_DISABLED);
	AddMenuItem(menu, "", "你现在要设置吗?", ITEMDRAW_DISABLED);
	
	AddMenuItem(menu, "0", "我要重新选一个");
	
	char m_szItem[4];
	Format(m_szItem, 4, "%d", buff);
	AddMenuItem(menu, m_szItem, "不选了就这个吧");

	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, false);
	DisplayMenu(menu, client, 0);
}

public int ConfirmSecondBuffMenuHandler(Handle menu, MenuAction action, int client, int itemNum) 
{
	if(action == MenuAction_Select) 
	{
		char info[32];
		GetMenuItem(menu, itemNum, info, 32);
		
		int buff = StringToInt(info);
		
		if(buff > 0)
			SetClientBuff(client, buff);
		else
			ShowSecondBuffToClient(client);
	}
	else if(action == MenuAction_Cancel && itemNum == MenuCancel_ExitBack)
	{
		ShowSecondBuffToClient(client);
	}
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

void SetClientBuff(int client, int buff)
{
	if(!g_eClient[client][bLoaded])
	{
		PrintToChat(client, "%s  很抱歉,你的数据尚未加载完毕", PLUGIN_PREFIX);
		return;
	}

	g_eClient[client][iBuff] = buff;

	char m_szQuery[256];
	Format(m_szQuery, 256, "UPDATE `playertrack_player` SET buff = '%d' WHERE id = '%d'", buff, g_eClient[client][iPlayerId]);
	SQL_TQuery(g_hDB_csgo, SQLCallback_SetBuff, m_szQuery, GetClientUserId(client));
}