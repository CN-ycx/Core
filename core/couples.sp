enum Couples
{
    iPartnerIndex,
    iPartnerPlayerId,
    iWeddingDate,
    String:szPartnerName[32]
}
enum Couples_Ranking
{
    iWeddingDay,
    iSource_PId,
    iTarget_Pid,
    String:szSource_Name[32],
    String:szTarget_Name[32]
}

int Couples_Data_Client_ProposeTargetUserId[MAXPLAYERS+1];
int Couples_Data_Client_ProposeSelectUserId[MAXPLAYERS+1];
int Couples_Data_Client_ProposeSelectedTime[MAXPLAYERS+1];

int Couples_Data_Client[MAXPLAYERS+1][Couples];

Handle Couples_Forward_OnWedding;
Handle Couples_Forward_OnDivorce;
Handle Couples_Menu_Ranking;
Handle Couples_Panel_About;

ArrayList Couples_Array_Ranking;

bool g_bDisableCouples = true;

void Couples_OnAskPluginLoad2()
{
    CreateNative("CG_CouplesGetPartnerIndex",    Native_Couples_GetPartnerIndex);
    CreateNative("CG_CouplesGetPartnerPlayerId", Native_Couples_GetPartnerPlayerId);
    CreateNative("CG_CouplesGetWeddingDate",     Native_Couples_GetWeddingDate);
    CreateNative("CG_CouplesGetPartnerName",     Native_Couples_GetPartnerName);
}

public int Native_Couples_GetPartnerIndex(Handle plugin, int numParams)
{
    return Couples_Data_Client[GetNativeCell(1)][iPartnerIndex];
}

public int Native_Couples_GetPartnerPlayerId(Handle plugin, int numParams)
{
    return Couples_Data_Client[GetNativeCell(1)][iPartnerPlayerId];
}

public int Native_Couples_GetWeddingDate(Handle plugin, int numParams)
{
    return Couples_Data_Client[GetNativeCell(1)][iWeddingDate];
}

public int Native_Couples_GetPartnerName(Handle plugin, int numParams)
{
    if(SetNativeString(2, Couples_Data_Client[GetNativeCell(1)][szPartnerName], GetNativeCell(3)) != SP_ERROR_NONE)
        ThrowNativeError(SP_ERROR_NATIVE, "Can not return Player partner name.");
}

void Couples_OnPluginStart()
{
    Couples_Forward_OnWedding = CreateGlobalForward("CG_OnCouplesWedding", ET_Ignore, Param_Cell, Param_Cell);
    Couples_Forward_OnDivorce = CreateGlobalForward("CG_OnCouplesDivorce", ET_Ignore, Param_Cell);
    
    RegConsoleCmd("sm_cp",      Command_Couples);
    RegConsoleCmd("sm_couples", Command_Couples);
    RegConsoleCmd("sm_propose", Command_Propose);
    
    RegServerCmd("cp_toggle",   Command_Toggle);
    
    Couples_Array_Ranking = CreateArray(view_as<int>(Couples_Ranking));
    
    Couples_CreateAboutMenu();
}

public Action Command_Toggle(int args)
{
    g_bDisableCouples = !g_bDisableCouples;
    PrintToServer("[Core]  Couples now %s!", g_bDisableCouples ? "Disabled" : "Enabled");
    PrintToChatAll("[\x0CCore\x01]  \x0ECouples now %s\x0E!", g_bDisableCouples ? "\x07Disabled" : "\x04Enabled");
    return Plugin_Handled;
}

public Action Command_Couples(int client, int args)
{
    if(!IsValidClient(client) || !g_ClientGlobal[client][bLoaded])
        return Plugin_Handled;

    Couples_DisplayMainMenu(client);

    return Plugin_Handled;
}

public Action Command_Propose(int client, int args)
{
    if(!IsValidClient(client) || !g_ClientGlobal[client][bLoaded])
        return Plugin_Handled;

    Couples_DisplayProposeMenu(client);

    return Plugin_Handled;
}

void Couples_OnClientConnected(int client)
{
    Couples_Data_Client[client][iPartnerIndex]    =  -2;
    Couples_Data_Client[client][iPartnerPlayerId] =   0;
    Couples_Data_Client[client][iWeddingDate]     =   0;
    Couples_Data_Client[client][szPartnerName][0] ='\0';
}

void Couples_OnClientDisconnect(int client)
{
    Couples_Data_Client_ProposeTargetUserId[client] = 0;
    Couples_Data_Client_ProposeSelectedTime[client] = 0;

    int target = Couples_Data_Client[client][iPartnerIndex];

    if(target < 1)
        return;

    Couples_Data_Client[target][iPartnerIndex] = -1;
}

void Couples_InitializeCouplesData(int client, int CP_PlayerId, int CP_WeddingDate, const char[] CP_PartnerName)
{
    Couples_Data_Client[client][iWeddingDate] = CP_WeddingDate;
    Couples_Data_Client[client][iPartnerPlayerId] = CP_PlayerId;

    if(CP_PlayerId < 1)
    {
        Couples_Data_Client[client][iPartnerIndex] = -2;
        Couples_Data_Client[client][iPartnerPlayerId] = 0;
        strcopy(Couples_Data_Client[client][szPartnerName], 32, "你是单身狗");
        return;
    }

    strcopy(Couples_Data_Client[client][szPartnerName], 32, CP_PartnerName);

    int m_iPartner = FindClientByPlayerId(CP_PlayerId);

    Couples_Data_Client[client][iPartnerIndex] = m_iPartner;

    if(IsValidClient(m_iPartner))
    {
        Couples_Data_Client[m_iPartner][iPartnerIndex] = client;
        PrintToChat(m_iPartner, "[\x0CCG\x01]   \x0E你的CP已经登陆游戏...");
        PrintToChat(client, "[\x0CCG\x01]   \x0E你的CP当前在线哦...");
    }
}

void Couples_DisplayMainMenu(int client)
{
    Handle menu = CreateMenu(MenuHandler_CouplesMainMenu);

    SetMenuExitButton(menu, true);
    SetMenuExitBackButton(menu, true);

    char date[64];
    FormatTime(date, 64, "%Y.%m.%d", Couples_Data_Client[client][iWeddingDate]);

    if(Couples_Data_Client[client][iPartnerPlayerId])
        SetMenuTitleEx(menu, "[CP]  主菜单 \n \n对象: %s\n日期: %s\n持久: %d天", Couples_Data_Client[client][szPartnerName], date, (GetTime()-Couples_Data_Client[client][iWeddingDate])/86400);
    else
        SetMenuTitleEx(menu, "[CP]  主菜单 \n \n对象: %s", Couples_Data_Client[client][szPartnerName]);

    AddMenuItemEx(menu, Couples_Data_Client[client][iPartnerPlayerId] == 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "receive", "求婚列表");
    AddMenuItemEx(menu, Couples_Data_Client[client][iPartnerPlayerId] == 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "propose", "发起求婚");
    AddMenuItemEx(menu, Couples_Data_Client[client][iPartnerPlayerId] != 0 ? ITEMDRAW_DEFAULT : ITEMDRAW_DISABLED, "divorce", "发起离婚");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "ranking", "登记列表");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "aboutcp", "功能介绍");

    DisplayMenu(menu, client, 20);
}

public int MenuHandler_CouplesMainMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, itemNum, info, 32);
            if(StrEqual(info, "receive"))       Couples_DisplayProposeMenu(client);
            else if(StrEqual(info, "propose"))  Couples_DisplaySeleteMenu(client);
            else if(StrEqual(info, "divorce"))  Couples_DisplayDivorceMenu(client);
            else if(StrEqual(info, "ranking"))  DisplayMenu(Couples_Menu_Ranking, client, 0);
            else if(StrEqual(info, "aboutcp"))  SendPanelToClient(Couples_Panel_About, client, MenuHandler_CouplesAboutCPPanel, 15);
        }
        case MenuAction_End:    CloseHandle(menu);
        case MenuAction_Cancel: if(itemNum == MenuCancel_ExitBack) Command_Menu(client, 0);
    }
}

void Couples_DisplaySeleteMenu(int client)
{
    int num = Couples_Data_Client[client][iWeddingDate] - GetTime();
    if(num > 0)
    {
        PrintToChat(client, "[\x0CCG\x01]   你还有\x04%d\x01秒才能再次组成CP", num);
        return;
    }

    num = Couples_Data_Client_ProposeSelectedTime[client] > GetTime()+60;
    if(num > 0)
    {
        PrintToChat(client, "[\x0CCG\x01]   请勿频繁发起请求,请等待\x04%d\x01秒后再试", num);
        return;
    }
    
    //if(g_bDisableCouples)
    //{
    //    PrintToChat(client, "[\x0CCore\x01]  \x0E当前CP系统维护中,暂时不能组成CP!");
    //    return;
    //}

    Handle menu = CreateMenu(MenuHandler_CouplesSelectMenu)

    char m_szId[8];
    for(int target = 1; target <= MaxClients; ++target)
    {
        // Current in game              self?               not loading?                    forum member?                       has partner?
        if(!IsClientInGame(target) || target == client || !g_ClientGlobal[target][bLoaded] || g_ClientGlobal[target][iUId] <= 0 || Couples_Data_Client[target][iPartnerPlayerId] != 0)
            continue;

        FormatEx(m_szId, 8, "%d", GetClientUserId(target));
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, m_szId, g_ClientGlobal[target][szGamesName]);
    }

    if(GetMenuItemCount(menu) < 1)
    {
        PrintToChat(client, "[\x0CCG\x01]   当前服务器内没有玩家能跟你组CP...");
        CloseHandle(menu);
        Couples_DisplayMainMenu(client);
        return;
    }

    SetMenuTitleEx(menu, "[CP]  选择CP对象");
    SetMenuExitBackButton(menu, true);
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 0);
}

public int MenuHandler_CouplesSelectMenu(Handle menu, MenuAction action, int source, int itemNum) 
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, itemNum, info, 32);
            
            int userid = StringToInt(info);
            int target = GetClientOfUserId(userid);

            if(!IsValidClient(target) || Couples_Data_Client[target][iPartnerPlayerId] != 0)
            {
                PrintToChat(source, "[\x0CCG\x01]   你选择的对象目前不可用#03");
                Couples_DisplayMainMenu(source);
                return;
            }

            Couples_Data_Client_ProposeTargetUserId[source] = userid;
            Couples_Data_Client_ProposeSelectedTime[source] = GetTime();
            Couples_DisplayProposeMenu(target);

            PrintToChat(source, "[\x0CCG\x01]   已将你的CP请求发送至\x0E%N", target);
        }
        case MenuAction_End:    CloseHandle(menu);
        case MenuAction_Cancel: if(itemNum == MenuCancel_ExitBack) Couples_DisplayMainMenu(source);
    }
}

void Couples_DisplayProposeMenu(int target)
{
    Handle menu = CreateMenu(MenuHandler_CouplesProposeMenu);
    
    int userid = GetClientUserId(target);
    
    char m_szId[8];
    for(int source = 1; source <= MaxClients; ++source)
    {
        // Current in game              self?               not loading?                    forum member?                       has partner?
        if(!IsClientInGame(source) || source == target || !g_ClientGlobal[source][bLoaded] || g_ClientGlobal[source][iUId] <= 0 || Couples_Data_Client[source][iPartnerPlayerId] != 0 || Couples_Data_Client_ProposeTargetUserId[source] != userid)
            continue;

        FormatEx(m_szId, 8, "%d", GetClientUserId(source));
        AddMenuItemEx(menu, ITEMDRAW_DEFAULT, m_szId, g_ClientGlobal[source][szGamesName]);
    }

    if(GetMenuItemCount(menu) < 1)
    {
        PrintToChat(target, "[\x0CCG\x01]   别自恋了,没人跟你求婚...");
        CloseHandle(menu);
        Couples_DisplayMainMenu(target);
        return;
    }

    SetMenuTitleEx(menu, "[CP]  求婚列表");
    SetMenuExitBackButton(menu, true);
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, target, 0);
}

public int MenuHandler_CouplesProposeMenu(Handle menu, MenuAction action, int target, int itemNum) 
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[32];
            GetMenuItem(menu, itemNum, info, 32);
            
            int userid = StringToInt(info);
            int source = GetClientOfUserId(userid);

            if(!IsValidClient(source) || Couples_Data_Client[source][iPartnerPlayerId] != 0)
            {
                PrintToChat(target, "[\x0CCG\x01]   你选择的对象目前不可用#01");
                Couples_DisplayMainMenu(target);
                return;
            }

            Couples_Data_Client_ProposeSelectUserId[target] = userid;
            Couples_DisplayConfrimMenu(target, source);
        }
        case MenuAction_End:    CloseHandle(menu);
        case MenuAction_Cancel: if(itemNum == MenuCancel_ExitBack) Couples_DisplayProposeMenu(target);
    }
}

void Couples_DisplayConfrimMenu(int target, int source)
{
    Handle menu = CreateMenu(MenuHandler_CouplesConfirmMenu);
    SetMenuTitleEx(menu, "[CP]  结婚登记");

    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "你收到了一个来自 %N 的CP邀请", source);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "组成CP后30天内不能申请解除");
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "组成CP后可以享受多种福利");
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "你确定要接受这个邀请吗");

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "accept", "接受请求");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "refuse", "拒绝请求");

    SetMenuExitButton(menu, false);
    DisplayMenu(menu, target, 0);
}

public int MenuHandler_CouplesConfirmMenu(Handle menu, MenuAction action, int target, int itemNum) 
{
    if(action == MenuAction_Select) 
    {
        char info[32];
        GetMenuItem(menu, itemNum, info, 32);
        
        int source = GetClientOfUserId(Couples_Data_Client_ProposeSelectUserId[target]);
        
        Couples_Data_Client_ProposeSelectUserId[source] = 0;
        Couples_Data_Client_ProposeSelectUserId[target] = 0;
        Couples_Data_Client_ProposeTargetUserId[source] = 0;
        Couples_Data_Client_ProposeTargetUserId[target] = 0;

        //accept?
        if(StrEqual(info, "accept"))
        {
            if(!IsValidClient(source) || Couples_Data_Client[source][iPartnerPlayerId] > 0)
            {
                PrintToChat(target, "[\x0CCG\x01]   你选择的对象目前不可用#02->%d.%d", source, Couples_Data_Client[source][iPartnerPlayerId]);
                Couples_DisplaySeleteMenu(target);
                return;
            }

            Couples_GetMarried(source, target);
        }
        //refuse?
        else
        {
            if(!IsValidClient(source))
                return;

            PrintToChat(target, "[\x0CCG\x01]   你拒绝了\x0E%N\x01的CP邀请", source);
            PrintToChat(source, "[\x0CCG\x01]   \x0E%N\x01拒绝了你的CP邀请", target);
        }
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}

void Couples_GetMarried(int source, int target)
{
    //her -> target
    //if(g_ClientGlobal[target][iPId] == 167606 && g_ClientGlobal[source][iPId] != 1)
    //{
    //    char cmd_callbacl[128];
    //    ServerCommandEx(cmd_callbacl, 128 , "sm_ban #%d 0 \"CAT: 你想干嘛?\"", GetClientUserId(source));
    //    UTIL_LogError("Couples_GetMarried", "Auto ban %s permanent: %s", g_ClientGlobal[source][szGamesName], cmd_callbacl);
    //    return;
    //}

    //her -> source
    //if(g_ClientGlobal[source][iPId] == 167606 && g_ClientGlobal[target][iPId] != 1)
    //{
    //    PrintToChat(source, "[\x0CCG\x01]   系统错误 \x02CP#33");
    //    PrintToChat(target, "[\x0CCG\x01]   系统错误 \x02CP#33");
    //    Couples_DisplayMainMenu(source);
    //    return;
    //}

    Handle m_hPack = CreateDataPack();
    WritePackCell(m_hPack, GetClientUserId(source));
    WritePackCell(m_hPack, GetClientUserId(target));
    WritePackCell(m_hPack, g_ClientGlobal[source][iPId]);
    WritePackCell(m_hPack, g_ClientGlobal[target][iPId]);
    ResetPack(m_hPack);

    //SQL CALL
    char m_szQuery[128];
    Format(m_szQuery, 128, "CALL lily_addcouple(%d, %d)", g_ClientGlobal[source][iPId], g_ClientGlobal[target][iPId]);
    MySQL_Query(false, Couples_SQLCallback_UpdateCP, m_szQuery, m_hPack);
}

public void Couples_SQLCallback_UpdateCP(Handle owner, Handle hndl, const char[] error, Handle pack)
{
    int source = GetClientOfUserId(ReadPackCell(pack));
    int target = GetClientOfUserId(ReadPackCell(pack));
    int srcpid = ReadPackCell(pack);
    int tgrpid = ReadPackCell(pack);
    CloseHandle(pack);
    
    bool SourceValid = IsValidClient(source);
    bool TargetValid = IsValidClient(target);

    if(hndl == INVALID_HANDLE)
    {
        if(TargetValid)
            PrintToChat(target, "[\x0CCG\x01]   系统错误 \x02CP#02");

        if(SourceValid)
            PrintToChat(source, "[\x0CCG\x01]   系统错误 \x02CP#02");

        UTIL_LogError("Couples_SQLCallback_UpdateCP", "UpdateCP->hndl [%d] <-> [%d] error: %s", srcpid, tgrpid, error);

        return;
    }

    if(!SQL_GetAffectedRows(hndl))
    {
        if(TargetValid)
            PrintToChat(target, "[\x0CCG\x01]   系统错误 \x02CP#03");

        if(SourceValid)
            PrintToChat(source, "[\x0CCG\x01]   系统错误 \x02CP#03");

        UTIL_LogError("Couples_SQLCallback_UpdateCP", "UpdateCP->Affected [%d] <-> [%d]", srcpid, tgrpid);

        return;
    }

    if(SourceValid && TargetValid)
    {
        Couples_Data_Client[source][iPartnerIndex] = target;
        Couples_Data_Client[source][iPartnerPlayerId] = g_ClientGlobal[target][iPId];
        Couples_Data_Client[source][iWeddingDate] = GetTime();
        Couples_Data_Client[target][iPartnerIndex] = source;
        Couples_Data_Client[target][iPartnerPlayerId] = g_ClientGlobal[source][iPId];
        Couples_Data_Client[target][iWeddingDate] = GetTime();
        strcopy(Couples_Data_Client[source][szPartnerName], 32, g_ClientGlobal[target][szGamesName]);
        strcopy(Couples_Data_Client[target][szPartnerName], 32, g_ClientGlobal[source][szGamesName]);

        Call_StartForward(Couples_Forward_OnWedding);
        Call_PushCell(source);
        Call_PushCell(target);
        Call_Finish();

        PrintToChatAll("[\x0CCG\x01]   \x10恭喜\x0E%N\x10和\x0E%N\x10结成CP.", source, target);
        Couples_DisplayMainMenu(source);
        Couples_DisplayMainMenu(target);
    }
    else if(SourceValid && !TargetValid)
    {
        Couples_Data_Client[source][iPartnerIndex] = -1;
        Couples_Data_Client[source][iPartnerPlayerId] = tgrpid;
        Couples_Data_Client[source][iWeddingDate] = GetTime();
        strcopy(Couples_Data_Client[source][szPartnerName], 32, "未知");

        PrintToChat(source, "系统已保存你们的数据,但是你CP当前离线,你不能享受新婚祝福");
        Couples_DisplayMainMenu(source);
    }
    else if(!SourceValid && TargetValid)
    {
        Couples_Data_Client[target][iPartnerIndex] = -1;
        Couples_Data_Client[target][iPartnerPlayerId] = srcpid;
        Couples_Data_Client[target][iWeddingDate] = GetTime();
        strcopy(Couples_Data_Client[target][szPartnerName], 32, "未知");

        PrintToChat(target, "[\x0CCG\x01]   系统已保存你们的数据,但是你CP当前离线,你不能享受新婚祝福");
        Couples_DisplayMainMenu(target);
    }
}

void Couples_DisplayDivorceMenu(int client)
{
    if((GetTime() - Couples_Data_Client[client][iWeddingDate]) < 1209600)
    {
        PrintToChat(client, "[\x0CCG\x01]   新组成CP之后14天内不能申请解除...");
        Couples_DisplayMainMenu(client);
        return;
    }
    
    if(g_bDisableCouples)
    {
        PrintToChat(client, "[\x0CCore\x01]  \x0E当前CP系统维护中,暂时不能解除CP!");
        return;
    }

    Handle menu = CreateMenu(MenuHandler_CouplesDivorceMenu);
    SetMenuTitleEx(menu, "[CP]  离婚登记台");

    char date[64];
    FormatTime(date, 64, "%Y.%m.%d %H:%M:%S", Couples_Data_Client[client][iWeddingDate]);

    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "你当前CP: %s", Couples_Data_Client[client][szPartnerName]);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "你们组成于 %s", date);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "你们已组成CP %d 天", (GetTime()-Couples_Data_Client[client][iWeddingDate])/86400);
    AddMenuItemEx(menu, ITEMDRAW_DISABLED, "", "你确定要解除CP组合吗");

    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "accept", "我已经不爱TA了");
    AddMenuItemEx(menu, ITEMDRAW_DEFAULT, "refuse", "我还是很爱TA的");

    SetMenuExitBackButton(menu, false);
    SetMenuExitButton(menu, false);
    DisplayMenu(menu, client, 0);
}

public int MenuHandler_CouplesDivorceMenu(Handle menu, MenuAction action, int client, int itemNum) 
{
    switch(action)
    {
        case MenuAction_Select:
        {
            char info[128];
            GetMenuItem(menu, itemNum, info, 128);
            
            if(StrEqual(info, "refuse", false))
            {
                Couples_DisplayMainMenu(client);
                return;
            }

            char m_szQuery[256];
            Format(m_szQuery, 256, "UPDATE `playertrack_player` SET lilyid = '-2', lilydate = %d where id = %d or lilyid = %d", GetTime()+2592000, g_ClientGlobal[client][iPId], g_ClientGlobal[client][iPId]);
            MySQL_Query(false, SQLCallback_UpdateDivorce, m_szQuery, GetClientUserId(client));
        }
        case MenuAction_End: CloseHandle(menu);
    }
}

public void SQLCallback_UpdateDivorce(Handle owner, Handle hndl, const char[] error, int userid)
{
    int client = GetClientOfUserId(userid);

    if(!IsValidClient(client))
        return;

    if(hndl == INVALID_HANDLE)
    {
        PrintToChat(client, "[\x0CCG\x01]   系统错误 \x02CP#06");
        UTIL_LogError("SQLCallback_UpdateDivorce", "UpdateDivorce %L error: %s", client, error);
        return;
    }

    PrintToChatAll("[\x0CCG\x01]   \x10%N\x05解除了和\x10%s\x05的CP,他们的关系维持了\x02%d\x05天", client, Couples_Data_Client[client][szPartnerName], (GetTime()-Couples_Data_Client[client][iWeddingDate])/86400);

    Call_StartForward(Couples_Forward_OnDivorce);
    Call_PushCell(client);
    Call_Finish();

    int target = Couples_Data_Client[client][iPartnerIndex];
    if(target > 0)
    {
        Couples_OnClientConnected(target);
        Couples_Data_Client[target][iWeddingDate] = GetTime()+1209600;
    }

    Couples_OnClientConnected(client);
    Couples_Data_Client[client][iWeddingDate] = GetTime()+1209600;
    Couples_DisplayMainMenu(client);
}

void Couples_CreateAboutMenu()
{
    Couples_Panel_About = CreatePanel();

    DrawPanelText(Couples_Panel_About, "[CP]  系统说明");
    DrawPanelText(Couples_Panel_About, " ");
    DrawPanelText(Couples_Panel_About, "组成CP需要两厢情愿,无法单方面组CP");
    DrawPanelText(Couples_Panel_About, "发起请求之后需要对方确认才能配对");
    DrawPanelText(Couples_Panel_About, "组成CP后14天内不能解除");
    DrawPanelText(Couples_Panel_About, "解除CP后14天内不能再组");
    DrawPanelText(Couples_Panel_About, "CP能为你提供一定的加成(道具商店,天赋等)");
    DrawPanelText(Couples_Panel_About, "按Y输入[/内容]可以发送CP频道");
    DrawPanelText(Couples_Panel_About, "还有更多的功能正在开发中...");
    DrawPanelText(Couples_Panel_About, "希望你和你的另1半在服务器里玩得开心");
    DrawPanelText(Couples_Panel_About, " ");
    DrawPanelText(Couples_Panel_About, " ");

    DrawPanelItem(Couples_Panel_About, "返回");
}

public int MenuHandler_CouplesAboutCPPanel(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
        Couples_DisplayMainMenu(client);
}

int FindClientByPlayerId(int playerid)
{
    for(int client = 1; client <= MaxClients; ++client)
        if(IsClientInGame(client) && g_ClientGlobal[client][bLoaded])
            if(g_ClientGlobal[client][iPId] == playerid)
                return client;

    return -1;
}

Action Couples_OnClientSay(int client, const char[] message)
{
    if(message[0] != '/')
        return Plugin_Continue;

    int target = Couples_Data_Client[client][iPartnerIndex];
    if(target == -2)
    {
        PrintToChat(client, "[\x0ECP频道\x01]  \x07你没有CP,发什么发");
        return Plugin_Stop;
    }
    else if(target == -1)
    {
        PrintToChat(client, "[\x0ECP频道\x01]  \x05你的CP \x0E%s \x05当前已经离线", Couples_Data_Client[client][szPartnerName]);
        return Plugin_Stop;
    }
    else if(!IsValidClient(target))
        return Plugin_Stop;
    
    ClientCommand(client, "play buttons/bell1.wav");
    ClientCommand(target, "play buttons/bell1.wav");

    PrintToChat(target, "[\x0ECP频道\x01]  \x0E%N\x01 :  \x10%s", client, message[1]);
    PrintToChat(client, "[\x0ECP频道\x01]  \x0E%N\x01 :  \x10%s", client, message[1]);

    return Plugin_Stop;
}

void Couples_BuildLilyRanking(ArrayList aPlayerId, ArrayList aNickname, ArrayList aLilyPIdx, ArrayList aLilyDate)
{
    ClearArray(Couples_Array_Ranking);
    
    if(Couples_Menu_Ranking != INVALID_HANDLE)
        CloseHandle(Couples_Menu_Ranking);
    
    Couples_Menu_Ranking = CreateMenu(MenuHandler_CouplesRanking);
    SetMenuTitleEx(Couples_Menu_Ranking, "[CP]  登记列表 (%d对)", GetArraySize(aPlayerId)/2);

    while(GetArraySize(aPlayerId) > 1)
    {
        Couples_Ranking data[Couples_Ranking];

        data[iSource_PId] = GetArrayCell(aPlayerId, 0);
        data[iTarget_Pid] = GetArrayCell(aLilyPIdx, 0);
        data[iWeddingDay] = GetArrayCell(aLilyDate, 0);

        GetArrayString(aNickname, 0, data[szSource_Name], 32);

        int index = FindValueInArray(aPlayerId, data[iTarget_Pid]);
        GetArrayString(aNickname, index, data[szTarget_Name], 32);
        if(GetArrayCell(aLilyPIdx, index) != data[iSource_PId])
            UTIL_LogError("Couples_BuildLilyRanking", "Load Couples List failed. %d.%s <-> %d.%s ? %d", data[iSource_PId], data[szSource_Name], data[iTarget_Pid], data[szTarget_Name], GetArrayCell(aPlayerId, index));

        RemoveFromArray(aPlayerId, index);
        RemoveFromArray(aNickname, index);
        RemoveFromArray(aLilyPIdx, index);
        RemoveFromArray(aLilyDate, index);
        
        RemoveFromArray(aPlayerId, 0);
        RemoveFromArray(aNickname, 0);
        RemoveFromArray(aLilyPIdx, 0);
        RemoveFromArray(aLilyDate, 0);

        index = PushArrayArray(Couples_Array_Ranking, data[0], view_as<int>(Couples_Ranking));

        char menuIndex[16];
        IntToString(index, menuIndex, 16);

        AddMenuItemEx(Couples_Menu_Ranking, ITEMDRAW_DEFAULT, menuIndex, "[%s] ♥ [%s]", data[szSource_Name], data[szTarget_Name]);
    }

    SetMenuExitButton(Couples_Menu_Ranking, true);
    SetMenuExitBackButton(Couples_Menu_Ranking, true);
}

public int MenuHandler_CouplesRanking(Handle menu, MenuAction action, int client, int itemNum) 
{
    if(action == MenuAction_Select) 
    {
        char info[16];
        GetMenuItem(menu, itemNum, info, 16);
        
        Couples_DisplayCPsDetails(client, StringToInt(info));
    }
    else if(action == MenuAction_Cancel)
        if(itemNum == MenuCancel_ExitBack)
            Couples_DisplayMainMenu(client);
}

void Couples_DisplayCPsDetails(int client, int index)
{
    Couples_Ranking data[Couples_Ranking];
    GetArrayArray(Couples_Array_Ranking, index, data[0], view_as<int>(Couples_Ranking));
    
    char date[64];
    FormatTime(date, 64, "%Y.%m.%d", data[iWeddingDay]);

    Handle panel = CreatePanel();

    DrawPanelTextEx(panel, "▽ Couples Details ▽");
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, "%s", data[szSource_Name]);
    DrawPanelTextEx(panel, "         ↑♥↓         ");
    DrawPanelTextEx(panel, "%s", data[szTarget_Name]);
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, "CP日期:  %s", date);
    DrawPanelTextEx(panel, "CP天数:  %d", (GetTime()-data[iWeddingDay])/86400);
    DrawPanelTextEx(panel, "CP排名:  %d", index+1);
    DrawPanelTextEx(panel, " ");
    DrawPanelTextEx(panel, " ");

    DrawPanelItem(panel, "返回");
    DrawPanelItem(panel, "退出");
    
    SendPanelToClient(panel, client, Couples_CPsDetailesPanel, 30);
}

public int Couples_CPsDetailesPanel(Handle menu, MenuAction action, int client, int itemNum)
{
    if(action == MenuAction_Select)
    {
        if(itemNum==1)
            DisplayMenu(Couples_Menu_Ranking, client, 0);
    }
    else if(action == MenuAction_End)
        CloseHandle(menu);
}