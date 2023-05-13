// code by watch/fm see https://github.com/ben-watch/feckinmad, modified by MrKoala in order to migrate skillzworld 
// from the c++ metamod plugin to amxmodx

#if defined _module_included
  #endinput
#endif
#define _module_included

#if AMXX_VERSION_NUM >= 175
 #pragma reqclass sw_thirdperson
 #if !defined AMXMODX_NOAUTOLOAD
  #pragma defclasslib sw_thirdperson sw_thirdperson
 #endif
#else
 #pragma library sw_thirdperson
#endif

public Native_GetUserThird(iPlugin, iParams);