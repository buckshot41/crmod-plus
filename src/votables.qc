//
// Votables.qc
//
// Code to handle all votes
//
// All code by J.P. Grossman unless otherwise commented
//

// global variables
string request_mapname;     // Used for requesting a new level
float request_timelimit;    // Used for requesting a new time limit
float request_overtime;		// Used for requesting a new overtime
float request_gibs;         // Used to set gib level
float request_mode;         // Used to request a new mode

void() UnHookPlayer;

//
//  S E N D  A L I A S E S
//
//  Stuffs aliases for votable commands and numbers.
//
void() votables_send_aliases =
{
	local entity temp;

	temp = self;
	self = self.owner;
	stuffcmd(self, "alias w5 \"wait;wait;wait;wait;wait\"\n");
	stuffcmd(self, "alias sethook impulse 202\n");
	stuffcmd(self, "alias setrunes impulse 203\n");
	// toggle faststarts	
	stuffcmd(self, "alias faststart impulse 209\n");
	stuffcmd(self, "alias autopause impulse 210\n");
	// toggle extended obits
	stuffcmd(self, "alias obits impulse 211\n");
	// timelimit aliases
	stuffcmd(self, "alias timeset impulse 215\n");
	stuffcmd(self, "alias otset impulse 216\n");
	// Quad, Pent, Ring aliases
	stuffcmd(self, "alias setquad impulse 221\n");
	stuffcmd(self, "alias setpent impulse 222\n");
	stuffcmd(self, "alias setring impulse 223\n");
	// gib aliases
	stuffcmd(self, "alias nogibs impulse 225\n");
	stuffcmd(self, "alias lowgibs impulse 226\n");
	stuffcmd(self, "alias highgibs impulse 227\n");
	// playmode aliases
	stuffcmd(self, "alias normal impulse 217\n");
	stuffcmd(self, "alias practice impulse 218\n");
	stuffcmd(self, "alias match impulse 219\n");
	stuffcmd(self, "alias dm cmd dm\n");
	stuffcmd(self, "alias ctf cmd ctf\n");
	// number aliases
	stuffcmd(self, "alias 0 impulse 230\n");
	stuffcmd(self, "alias 1 impulse 231\n");
	stuffcmd(self, "alias 2 impulse 232\n");
	stuffcmd(self, "alias 3 impulse 233\n");
	stuffcmd(self, "alias 4 impulse 234\n");
	stuffcmd(self, "alias 5 impulse 235\n");
	stuffcmd(self, "alias 6 impulse 236\n");
	stuffcmd(self, "alias 7 impulse 237\n");
	stuffcmd(self, "alias 8 impulse 238\n");
	stuffcmd(self, "alias 9 impulse 239\n");
	stuffcmd(self, "alias 10 impulse 240\n");
	stuffcmd(self, "alias 11 impulse 241\n");
	stuffcmd(self, "alias 12 impulse 242\n");
	stuffcmd(self, "alias 13 impulse 243\n");
	stuffcmd(self, "alias 14 impulse 244\n");
	stuffcmd(self, "alias 15 impulse 245\n");
	// send this LAST to make sure that client received all impulses
	stuffcmd(self, "alias clanring_ignorethis \"impulse 180 ; sm0\"\n");
	self = temp;
	remove(self);
};

//----------------------------------------------------------------
//	V O T A B L E S  S E T  H O O K
//
//	R00K: Enable or disable the hook, only for ctf
//	(TODO): allow in pub-tdm?
//			voteable speeds for QW players
//----------------------------------------------------------------
void() votables_set_hook =
{
	local entity p;
	
	if (!(clanring_playmode & CLANRING_NO_HOOK))
	{
		clanring_playmode = (clanring_playmode | CLANRING_NO_HOOK);

		p = find(world, classname, "player");

		while (p)
		{
			if (p.style & CLANRING_CONNECTED)
			{				
				if (p.weapon == IT_HOOK)
				{
					local entity tmp;
					tmp = self;
					self = p;
					UnHookPlayer();							
					self = tmp;
					p.weapon = IT_AXE;
				}			
				self.hook2 = (self.hook2 - (self.hook2 & HOOK_OUT));	
			}
			p= find(p ,classname , "player");			
		}
		bprint("grappling hook has been \bdisabled\n");
	}
	else
	{
		if (clanring_playmode & CLANRING_NO_HOOK)
		{
			clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_NO_HOOK);
			bprint("grappling hook has been \benabled\n");
		}					
	}

	utils_set_cvar("samelevel", clanring_playmode);	
};

void() votables_request_set_hook =
{
	local string newstate = "", newstate2 = "";

	if (clanring_request)
	{
		sprint(self, "There is already a vote in progress\n");
		return;
	}

	if (self.style & CLANRING_ADMINISTRATOR)
	{
		votables_set_hook();
		return;
	}

	if (!(clanring_playmode & CLANRING_NO_HOOK))
	{
		newstate  = "disable";
		newstate2 = " grappling hook";
	}
	else
	{
		if (clanring_playmode & CLANRING_NO_HOOK)
		{
			newstate  = "enable";
			newstate2 = " grappling hook";
		}
	}						
	
	if (vote_init(newstate, newstate2, votables_set_hook))
	{
		vote_yes();
	}	
};

string request_mapname;

//
//  C H A N G E  L E V E L
//
//  Called when a request to change level passses.  The level name is
//  stored in request_mapname.
//
void () votables_change_level =
{
	if (clanring_state & CLANRING_MATCH_STARTED)
	return;

	utils_set_cvar("timelimit", clanring_timelimit);

	if (request_mapname == "start0")
	{
		serverflags = 0;
		changelevel("start");
	}
	else if (request_mapname == "start1")
	{
		serverflags = 15;
		changelevel("start");
	}
	else
	changelevel (request_mapname);
};


//
//  R E Q U E S T  C H A N G E  L E V E L
//
//  Called when a player requests a new level.
//
void(optional string requestmap = "") votables_request_change_level =
{
	local float level;
	local string newmap;

	self.use = SUB_Null;

	if (clanring_levelcount != -1)
	{
		sprint(self, "Wait for map to initialize\n");
		return;
	}

	if (clanring_state & CLANRING_MATCH_STARTED)
	{
		sprint(self, "Cannot change level while match is in progress.\n");
		return;
	}

	if (requestmap == "")
	{
		level = (self.warp_episode * 10) + (self.warp_map);//new r00k
		newmap = warpmap[level].name;
	} else {
		newmap = requestmap;
	}
	//clear warp_flags;
	self.warp_episode=0;
	self.warp_map=0;

	if (newmap == "")
	{
		sprint(self, "Invalid level\n");
		self.warp_episode=0;
		self.warp_map=0;
		return;
	}

    // Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		request_mapname = newmap;
		self.warp_episode=0;
		self.warp_map=0;
		votables_change_level();
	}
	else
	if (vote_init("������������� ", newmap, votables_change_level))
	{
		request_mapname = newmap;
		vote_yes();
	}

};


//
//  I N I T  W A R P
//
//  Called to initiate the warp.  The episode is passed as a parameter.
//  The level will be entered next; votables_request_change_level will be
//  called when it is.
//
void(float episode) votables_init_warp =
{
	self.count = episode;
	self.use = votables_request_change_level;
};

void() votables_starve_player =
{
	self.items = 0;
	self.items = (IT_SHOTGUN | IT_AXE);

	if (!(clanring_playmode & CLANRING_NO_HOOK))
		self.items = (self.items | IT_HOOK);

	self.health = 100;
	self.armorvalue = 0;
	self.ammo_shells = 0;
	self.ammo_nails = 0;
	self.ammo_rockets = 0;
	self.ammo_cells = 0;
	self.weapon = 1;
	self.armortype = 0;
	self.weaponmodel = "progs/v_shot.mdl";
	self.weaponframe = 0;
};

//
//  P H A T T E N  P L A Y E R
//
//  Phatten up players when entering practice mode.
//
void() votables_phatten_player =
{
	self.items = IT_SHOTGUN | IT_AXE | IT_ROCKET_LAUNCHER | IT_ARMOR3 | IT_SUPER_SHOTGUN | IT_NAILGUN | IT_GRENADE_LAUNCHER | IT_LIGHTNING | IT_SUPER_NAILGUN;

	if (!(clanring_playmode & CLANRING_NO_HOOK))
		self.items = self.items | IT_HOOK;

	self.health = 100;
	self.armorvalue = 200;
	self.ammo_shells = 100;
	self.ammo_nails = 200;
	self.ammo_rockets = 100;
	self.ammo_cells = 100;
	self.weapon = 32;
	self.armortype = 0.8;
	self.weaponmodel = "progs/v_rock2.mdl";
	self.weaponframe = 0;
};

//
//  S E T  M O D E
//
//  Called when a request to set the mode passes.
//
void() votables_set_mode =
{
	if (clanring_state & CLANRING_MATCH_STARTED)
		return;

	clanring_playmode = clanring_playmode - (clanring_playmode & (CLANRING_NORMAL_MODE | CLANRING_MATCH_MODE | CLANRING_PRACTICE_MODE));
	
	// Set the default timelimit if it was not set by options	
	if (!(self.style & CLANRING_SETTING_OPTIONS) || (self.pos1_x != cvar ("timelimit")))
	{
		if (request_mode == ADMIN_NORMAL_MODE)
		{
			utils_set_cvar("timelimit", clanring_timelimit);
			
			cvar_set("teamplay", "0");
			
			utils_do_players(votables_starve_player);//R00k ADDED, going from pmode to normal everyone has full inventory. (CVAR?)
			clanring_playmode = clanring_playmode | CLANRING_NORMAL_MODE;
		}
		else
		{
			if (request_mode == ADMIN_PRACTICE_MODE)
			{
				cvar_set("timelimit", "0");
				cvar_set("teamplay", "0");
			}
		}
	}

	if (request_mode == ADMIN_PRACTICE_MODE)
	{
		cvar_set("timelimit", "0");
		cvar_set("teamplay", "0");
		clanring_playmode = clanring_playmode | CLANRING_PRACTICE_MODE;
		utils_do_players(votables_phatten_player);
	}
	else
	{
		if (request_mode == ADMIN_MATCH_MODE)
		{
			clanring_playmode = clanring_playmode | CLANRING_MATCH_MODE;
			utils_do_players(votables_starve_player);//R00k ADDED
			utils_set_cvar("timelimit", clanring_timelimit);
			
			if (!(self.style & CLANRING_SETTING_OPTIONS))
			{
				if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
					cvar_set("teamplay", "1");//default for CTF
				else
					cvar_set("teamplay", "2");
			}	
		}
		else
		{
			if (request_mode == ADMIN_NORMAL_MODE)
			{
				utils_set_cvar("timelimit", clanring_timelimit);
				cvar_set("teamplay", "0");
				utils_do_players(votables_starve_player);
				clanring_playmode = clanring_playmode | CLANRING_NORMAL_MODE;
			}
		}
	}

	local string mode;
	mode = strings_get_mode(request_mode);
	announce3("playmode set to '", mode, "'");
	utils_set_cvar("samelevel", clanring_playmode);
	changelevel(mapname);
};

//
//  R E Q U E S T  S E T  M O D E
//
//  Request to change to the mode indicated by 'newmode':
//
//      0   -   normal
//      1   -   practice
//      2   -   match
//		3	-	individual
//
void(float newmode) votables_request_set_mode =
{
	local string mode;

	if (clanring_levelcount != -1)
	{
		if (self == world)
			cprint("Wait for levels.cfg to finish\n");
		else
			sprint(self, "Wait for map to initialize\n");
		return;
	}
	mode = strings_get_mode (newmode);
	if ((newmode == options_get_mode()) && !(self.style & CLANRING_SETTING_OPTIONS))
	{
		if (self == world)
			cprint3("Already in ", mode, " mode\n");
		else
			sprint3(self, "Already in ", mode, " mode\n");
		return;
	}
	mode = strings_get_mode_gold(newmode);
	if (clanring_state & CLANRING_MATCH_STARTED)
	{
		if (self == world)
			cprint("Cannot change mode while match is in progress\n");
		else
			sprint(self, "Match has started; cannot change mode\n");
		return;
	}
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		request_mode = newmode;
		votables_set_mode();
	}
	else
	{
		if (!(clanring_playmode & CLANRING_MODE_VOTE))
		{
			sprint(self, "Mode voting has been disabled\n");
		}
		else
		{
			if ((newmode == 1) && (clanring_state & CLANRING_NO_PRACTICE))
				sprint(self, "Practice mode has been disabled\n");
			else
			{
				if (vote_init("������������ ", mode, votables_set_mode))
				{
					request_mode = newmode;
					vote_yes();
				}
			}
		}
	}
};

//
// V O T A B L E S  S E T  G A M E T Y P E
//
//  r00k: This flips the whole server into either CTF or TEAM-Deathmatch, 
//  with sub-modes for each (match, normal, pmode)...
//
void(void) votables_set_gametype_dm =
{
	if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
		clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_CAPTURE_THE_FLAG);
	bprint("gametype set to Deathmatch\n");

	utils_set_cvar ("samelevel", clanring_playmode);

	changelevel ("dm3");	
};

void(void) votables_set_gametype_ctf =
{
	if (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG))
		clanring_playmode = (clanring_playmode | CLANRING_CAPTURE_THE_FLAG);
	bprint("gametype set to Capture The Flag\n");

	utils_set_cvar ("samelevel", clanring_playmode);

	changelevel ("ctf1");	
};

//
//	V O T A B L E S  R E Q U E S T  S E T  G A M E T Y P E
//
//	r00k: Vote to change gametype to CTF (1) or TDM (0)
//
void(float ctf) votables_request_set_gametype =
{
	if (clanring_state & CLANRING_MATCH_STARTED)
	{
		sprint(self, "Cannot change gametype while match is in progress\n");
		return;
	}

	if (time < 4)
	{
		sprint(self, "The server is still initializing, please try again.\n");
		return;//(REQUIRED for FTEsv)
	}

	//If ya'll could pass my vote, thanks!
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		if (ctf)
		{
			votables_set_gametype_ctf();
			
		}
		else
		{
			votables_set_gametype_dm();
		}
	}
	else
	{
		if (!ctf)
		{
			if (!(clanring_playmode & CLANRING_CAPTURE_THE_FLAG))
			{
				sprint(self, "Already in DeathMatch mode\n");
				return;
			}
			if (vote_init("\bChange Gametype to \b","Team DeathMatch", votables_set_gametype_dm))
			{				
				vote_yes();
			}
		}
		else
		{
			if (clanring_playmode & CLANRING_CAPTURE_THE_FLAG)
			{
				sprint(self, "Already in Capture The Flag mode\n");
				return;
			}
			if (vote_init("\bChange Gametype to \b","Capture The Flag", votables_set_gametype_ctf))
			{
				vote_yes();
			}
		}				
	}
};

//
//  S E T  T I M E L I M I T
//
//  Called when a request to change the timelimit passes.  The new
//  timelimit is stored in the global variable request_timelimit.
//
void() votables_set_timelimit =
{
	local string temp;

	if (clanring_playmode & CLANRING_MATCH_MODE)
	{
		clanring_timelimit = request_timelimit;
		default_timelimit = clanring_timelimit;
		temp = ftos(clanring_timelimit);
		bprint("Match length changed to ", temp, " minutes\n");
		match_show_timelimit();
	}
	else
	{
		timelimit = request_timelimit * 60;
		utils_set_cvar("timelimit", request_timelimit);
		temp = ftos(request_timelimit);
		bprint3("timelimit changed to ", temp, " minutes\n");
	}
};

//
//  R E Q U E S T  S E T  T I M E L I M I T
//
//  Called when a player requests a new timelimit.
//

void (float newlimit) votables_request_set_timelimit =
{
	local string temp;

	if (clanring_state & CLANRING_MATCH_STARTED)
	{
		sprint(self, "Cannot change time limit while match is in progress.\n");
		return;
	}

    // Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		request_timelimit = newlimit;
		votables_set_timelimit ();
	}
	else
	{
		temp = strings_ftos_bronze (newlimit);
		if (vote_init("change match length to ", temp, votables_set_timelimit))
		{
			request_timelimit = newlimit;
			vote_yes();
		}
	}
};

//
//  G E T  T I M E L I M I T
//
void() votables_get_timelimit =
{
	if (self.finaldest_z >= 1 && self.finaldest_z <= 6)
		votables_request_set_timelimit(self.finaldest_z * 5);
	else
		sprint(self, "invalid selection\n");
	self.use = SUB_Null;
};

//
//  S E L E C T  T I M E L I M I T
//
void() votables_select_timelimit =
{
	if (!(clanring_playmode & CLANRING_MATCH_MODE))
	{
		sprint(self, "Command valid in match mode only\n");
		return;
	}
	if (clanring_state & CLANRING_MATCH_STARTED)
	{
		sprint(self, "Cannot change time limit while match is in progress.\n");
		return;
	}
	sprint(self, "Select timelimit:\n");
	sprint(self, "��� � �������     ��� �� �������\n");
	sprint(self, "��� �� �������    ��� �� �������\n");
	sprint(self, "��� �� �������    ��� �� �������\n");
	self.use = votables_get_timelimit;
};

// 
//  S E T  O V E R T I M E
//
void() votables_set_overtime =
{
	local string temp;
	local string szplural;

	clanring_overtime = request_overtime;
	if (clanring_state & CLANRING_MATCH_STARTED)
	{
		sprint(self, "Cannot change overtime while match is in progress.\n");
		return;
	}
	if (clanring_overtime == -1)
	{
		announce("Overtime set to Sudden Death");
	}
	else
	{
		if (clanring_overtime == 0)
		{
			announce("Overtime disabled");
		}
		else
		{
			temp = ftos(clanring_overtime);
			szplural = strings_szplural(clanring_overtime);
			announce4("Overtime changed to ", temp, " minute", szplural);
		}
	}

	utils_set_cvar("scratch2", clanring_overtime);
};

//
//  R E Q U E S T  S E T  O V E R T I M E
//
void(float overtime) votables_request_set_overtime =
{
	local string temp;

	overtime = floor(overtime);
	if (clanring_state & CLANRING_MATCH_STARTED)
	{
		sprint(self, "Cannot change overtime while match is in progress.\n");
		return;
	}
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		request_overtime = overtime;
		votables_set_overtime ();
	}
	else
	{
		if (overtime == 0)
		{
			if (vote_init("���������������", "", votables_set_overtime))
			{
				request_overtime = overtime;
				vote_yes();
			}
		}
		else
		{
			if (overtime < 0)
			{
				temp = "�����������";
			}
			else
			{
				temp = strings_ftos_bronze (overtime);
			}
			if (vote_init("���������������� ", temp, votables_set_overtime))
			{
				request_overtime = overtime;
				vote_yes();
			}
		}
	}
};

//
//  G E T  O V E R T I M E
//
void () votables_get_overtime =
{
	if (self.finaldest_z < 6)
	votables_request_set_overtime(self.finaldest_z);
	else if (self.finaldest_z == 6)
	votables_request_set_overtime(10);
	else if (self.finaldest_z == 7)
	votables_request_set_overtime(-1);
	else
	sprint(self, "invalid selection\n");

	self.use = SUB_Null;
};


//
//  S E L E C T  O V E R T I M E
//

void() votables_select_overtime =
{
	if (!(clanring_playmode & CLANRING_MATCH_MODE))
	{
		sprint(self, "Command valid in match mode only\n");
		return;
	}
	if (clanring_state & CLANRING_MATCH_STARTED)
	{
		sprint(self, "Cannot change overtime while match is in progress.\n");
		return;
	}
	sprint(self, "Select overtime:\n");
	sprint(self, "��� ��������      ��� � �������\n");
	sprint(self, "��� � ������      ��� � �������\n");
	sprint(self, "��� � �������     ��� �� �������\n");
	sprint(self, "��� � �������     ��� ������ �����\n");
	self.use = votables_get_overtime;
};

//
//  S E T  G I B S
//
//  Called when a request to set gibs passes.  The new setting for gibs
//  is specified by the global variable request_gibs.
//
void() votables_set_gibs =
{
	clanring_playmode = (clanring_playmode - (clanring_playmode & (CLANRING_NO_GIBS | CLANRING_LOW_GIBS)));
	if (request_gibs == 0)
	{
		clanring_playmode = clanring_playmode | CLANRING_NO_GIBS;
		announce("Gibs disabled");
	}
	else
	{
		if (request_gibs == 1)
		{
			clanring_playmode = clanring_playmode | CLANRING_LOW_GIBS;
			announce("Gibs set to 'low'");
		}
		else
		{
			announce("Gibs set to 'high'");
		}
	}
	utils_set_cvar ("samelevel", clanring_playmode);
};

//
//  R E Q U E S T  S E T  G I B S
//
//  Called when a player requests a new setting for gibs.
//

void (float gibs) votables_request_set_gibs =
{
	if (clanring_playmode & CLANRING_NO_GIBS)
	{
		if (gibs == 0)
		{
			if (self == world)
			cprint("Gibs already disabled\n");
			else
			sprint(self, "Gibs already disabled\n");
			return;
		}
	}
	else if (clanring_playmode & CLANRING_LOW_GIBS)
	{
		if (gibs == 1)
		{
			if (self == world)
			cprint("\"Gibs already set to 'low'\"\n");
			else
			sprint(self, "Gibs already set to 'low'\n");
			return;
		}
	}
	else
	{
		if (gibs == 2)
		{
			if (self == world)
			cprint("\"Gibs already set to 'high'\"\n");
			else
			sprint(self, "Gibs already set to 'high'\n");
			return;
		}
	}

	// Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		request_gibs = gibs;
		votables_set_gibs();
	}
	else
	{
		local string gibmode;
		if (gibs == 0)
		gibmode = "'disabled'";
		else if (gibs == 1)
		gibmode = "'low'";
		else
		gibmode = "'high'";
		if (vote_init("������������ ", gibmode, votables_set_gibs))
		{
			request_gibs = gibs;
			vote_yes();
		}
	}
};

//
//  D I S A B L E  I T E M
//
//  Used to disable quad/pent/ring.  Called with the item as 'self'.
//

void () votables_disable_item =
{
	self.effects = self.effects - (self.effects & self.effects);
	self.model = string_null;
	self.solid = SOLID_NOT;
	self.nextthink = 9999999; // must be really big for quaketv
};

//
//  S E T  Q U A D
//
//  Enable/disable quad.
//
void () votables_set_quad =
{
	if (clanring_playmode & CLANRING_NO_QUAD)
	{
		utils_do_item(SUB_regen, "item_artifact_super_damage");
		bprint("Quad enabled\n");
		clanring_playmode = clanring_playmode - CLANRING_NO_QUAD;
	}
	else
	{
		utils_do_item(votables_disable_item, "item_artifact_super_damage");
		bprint("Quad disabled\n");
		clanring_playmode = clanring_playmode | CLANRING_NO_QUAD;
	}
	utils_set_cvar("samelevel", clanring_playmode);
};

//
//  R E Q U E S T  S E T  Q U A D
//
//  Request to enable/disable quad.
//
void() votables_request_set_quad =
{
	// Do it right away if we're an administrator, otherwise vote	
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		if (clanring_state & (CLANRING_SETQUAD_COUNT * 4))
		{
			sprint(self, "Stop fucking with the quad\n");
			return;
		}
		clanring_state = clanring_state + CLANRING_SETQUAD_COUNT;
		votables_set_quad ();
	}
	else
	{
		local string newstate;
		if (clanring_playmode & CLANRING_NO_QUAD)
			newstate = "������";
		else
			newstate = "�������";

		if (vote_init(newstate, " ����", votables_set_quad))
			vote_yes();
	}
};

void() GotoNextMap;
void() votables_vote_exit =
{
	if ((clanring_levelcount == -1))
	{
		GotoNextMap();
	}
};

void() votables_request_vote_exit =
{
	if (clanring_levelcount != -1)
	{
		sprint(self, "Wait for map to initialize\n");
		return;
	}
	
	if (clanring_playmode & CLANRING_MATCH_MODE)
	{
		sprint(self,"Command not allowed in match mode.\n");
		return;
	}

	if (self.style & CLANRING_ADMINISTRATOR)
		votables_vote_exit();
	else
	{
		local string newstate;
		sprint(self,"\byou have voted to exit to the next level.\n\botherwise, use WARP to specify map.\n");
		
		newstate = " exit to ";
		if (vote_init(newstate, "next level.", votables_vote_exit))
			vote_yes();
	}
};

//
//  S E T  P E N T
//
//  Enable/disable pentagram.
//
void() votables_set_pent =
{
	if (clanring_playmode & CLANRING_NO_PENT)
	{
		utils_do_item(SUB_regen, "item_artifact_invulnerability");
		announce("Pentagram enabled");
		clanring_playmode = clanring_playmode - CLANRING_NO_PENT;
	}
	else
	{
		utils_do_item(votables_disable_item, "item_artifact_invulnerability");
		announce("Pentagram disabled");
		clanring_playmode = clanring_playmode | CLANRING_NO_PENT;
	}
	utils_set_cvar("samelevel", clanring_playmode);
};

//
//  R E Q U E S T  S E T  P E N T
//
//  Request to enable/disable pentagram.
//
void() votables_request_set_pent =
{
	// Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		if (clanring_state & (CLANRING_SETPENT_COUNT * 4))
		{
			sprint(self, "Stop fucking with the pentagram\n");
			return;
		}
		clanring_state = clanring_state + CLANRING_SETPENT_COUNT;
		votables_set_pent();
	}
	else
	{
		local string newstate;
		if (clanring_playmode & CLANRING_NO_PENT)
			newstate = "������";
		else
			newstate = "�������";

		if (vote_init(newstate, " ���������", votables_set_pent))
			vote_yes();
	}
};

//
//  S E T  R I N G
//
//  Enable/disable ring of shadows.
//
void() votables_set_ring =
{
	if (clanring_playmode & CLANRING_NO_RING)
	{
		utils_do_item(SUB_regen, "item_artifact_invisibility");
		announce("Ring of shadows enabled");
		clanring_playmode = clanring_playmode - (clanring_playmode & CLANRING_NO_RING);
	}
	else
	{
		utils_do_item(votables_disable_item, "item_artifact_invisibility");
		announce("Ring of shadows disabled");
		clanring_playmode = clanring_playmode | CLANRING_NO_RING;
	}
	utils_set_cvar ("samelevel", clanring_playmode);
};

//
//  R E Q U E S T  S E T  R I N G
//
//  Request to enable/disable ring of shadows.
//
void() votables_request_set_ring =
{
	// Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	{
		if (clanring_state & (CLANRING_SETRING_COUNT * 4))
		{
			sprint(self, "Stop fucking with the ring\n");
			return;
		}
		clanring_state = clanring_state + CLANRING_SETRING_COUNT;
		votables_set_ring();
	}
	else
	{
		local string newstate;
		if (clanring_playmode & CLANRING_NO_RING)
		newstate = "������";
		else
		newstate = "�������";

		if (vote_init(newstate, " �������������", votables_set_ring))
			vote_yes();
	}
};

//
//  S E T  O B I T S
//
//  Enable/disable extended obituaries.
//
void() votables_set_obits =
{
	utils_toggle_sflag (CLANRING_EXTENDED_OBITS, "Extended obituaries");
};

//
//  R E Q U E S T  S E T  O B I T S
//
//  Request to enable/disable extended obituaries.
//
void() votables_request_set_obits =
{
    // Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
	utils_toggle_sflag(CLANRING_EXTENDED_OBITS, "Extended obituaries");
	else
	{
		local string newstate;
		if ((clanring_playmode & CLANRING_EXTENDED_OBITS))
		newstate = "�������";
		else
		newstate = "������";

		if (vote_init(newstate, " ���������������", votables_set_obits))
			vote_yes();
	}
};

//
//  S E T  A U T O P A U S E
//
//  Enable/disable autopausing
//
void() votables_set_autopause =
{
	utils_toggle_sflag (CLANRING_AUTO_PAUSE, "Automatic match pausing");
};

//
//  R E Q U E S T  S E T  A U T O P A U S E
//
//  Request to enable/disable autopausing
//

void() votables_request_set_autopause =
{

	// Do it right away if we're an administrator, otherwise vote
	if (self.style & CLANRING_ADMINISTRATOR)
		utils_toggle_sflag(CLANRING_AUTO_PAUSE, "Automatic match pausing");
	else
	{
		local string newstate;
		if (clanring_playmode & CLANRING_AUTO_PAUSE)
			newstate = "�������";
		else
			newstate = "������";

		if (vote_init(newstate, " ��������������", votables_set_autopause))
			vote_yes();
	}
};

void() StartRuneSpawn;
void() DropRune;

void() votables_set_runes =
{
	if (clanring_playmode & CLANRING_RUNES)
	{		
		utils_do_players(DropRune);
		utils_do_item(SUB_Remove, "item_rune");
		bprint("Runes Disabled\n");		
		clanring_playmode = (clanring_playmode - (clanring_playmode & CLANRING_RUNES));
		utils_set_cvar("samelevel", clanring_playmode);
	}
	else
	{	
		StartRuneSpawn ();
		bprint("Runes Enabled\n");
		clanring_playmode = (clanring_playmode | CLANRING_RUNES);
		utils_set_cvar("samelevel", clanring_playmode);
	}
};

void() votables_request_set_runes =
{
	local string newstate;

	if ((self.style) & CLANRING_ADMINISTRATOR) 
	{
		votables_set_runes ();
	}
	else
	{
		if (!(clanring_playmode & CLANRING_RUNES))
		{		   
			newstate = "\benable\b";
		}
		else
		{
			newstate = "\bdisable\b";
		}
		
		if (vote_init(newstate, " �����", votables_set_runes))
		{
			vote_yes();
		}
	}
};

//
//  S E T  F A S T S T A R T S
//
//  Enable/disable faststarts
//
void() votables_set_faststarts =
{
	utils_toggle_sflag (CLANRING_FAST_START, "Fast match starts");
};

//
//  R E Q U E S T  S E T  F A S T S T A R T S
//
//  Request to enable/disable faststarts
//
void() votables_request_set_faststarts =
{
	local string newstate;

	if ((self.style & CLANRING_ADMINISTRATOR))
	{
		votables_set_faststarts ();
	}
	else
	{
		if ((clanring_playmode & CLANRING_FAST_START))
		{
			newstate = "\bdisable\b";
		}
		else
		{
			newstate = "\benable\b";
		}
		if (vote_init(newstate, " fast match starts", votables_set_faststarts))
		{
			vote_yes();
		}
	}
};

