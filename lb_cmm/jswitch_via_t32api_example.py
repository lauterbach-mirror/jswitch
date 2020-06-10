#!/usr/bin/python
# -*- coding: latin-1 -*-
#

import platform
import ctypes

def jtagInitPrePost(t32api):
  status = 0
  # configure lots of IRPRE bits -> all other TAPs go to BYPASS
  # use Run-Test-Idle as default state
  # all other settings "default"
  status = t32api.T32_TAPAccessSetInfo(128,0,0,0,0,12,0,0)
  if status!=0:
    raise Exception("Error happens!")
  return

def jtagInitAndTAPReset(t32api):
  status = 0
  tapAccessEnOut = 0x24
  tapAccessSet0  = 0x2
  null = ctypes.POINTER(ctypes.c_int)()
  data = (tapAccessEnOut|tapAccessSet0).to_bytes(1, byteorder='little')
  status += t32api.T32_TAPAccessDirect(1, 1, data, null)
  status += t32api.T32_TAPAccessJTAGResetWithTMS(0, 0)
  if status!=0:
    raise Exception("Error happens!")
  return
  
def jtagInitTAPResetAndIdCodeRead(t32api):
  status = 0
  jtagInitAndTAPReset(t32api)
  data = ctypes.create_string_buffer(4)
  null = ctypes.POINTER(ctypes.c_int)()
  status += t32api.T32_TAPAccessShiftDR(0, 32, null, data)
  if status!=0:
    raise Exception("Error happens!")
  return bytes(data)

def jswitchReadReg(t32api, address):
  status = 0
  data = ctypes.create_string_buffer(2)
  null = ctypes.POINTER(ctypes.c_int)()
  address = (((address&0xf0000)>>4)|(address&0x7)).to_bytes(2, byteorder='little')
  status += t32api.T32_TAPAccessShiftIR(1, 4, bytes([0xc]), null)
  status += t32api.T32_TAPAccessShiftDR(1, 16, address, null)
  status += t32api.T32_TAPAccessShiftIR(1, 4, bytes([0xa]), null)
  status += t32api.T32_TAPAccessShiftDR(0, 16, null, data)
  if status!=0:
    raise Exception("Error happens!")
  data=bytes(data)
  return data
  
def jswitchWriteReg(t32api, address, value):
  status = 0
  null = ctypes.POINTER(ctypes.c_int)()
  address = (((address&0xf0000)>>4)|(address&0x7))
  data = ((address<<16)|(value&0xffff)).to_bytes(4, byteorder='little')
  status += t32api.T32_TAPAccessShiftIR(1, 4, bytes([0xd]), null)
  status += t32api.T32_TAPAccessShiftDR(0, 32, data, null)
  if status!=0:
    raise Exception("Error happens!")
  return

# auto-detect the correct library
if (platform.system()=='Windows') or (platform.system()[0:6]=='CYGWIN') :
  if ctypes.sizeof(ctypes.c_voidp)==4:
    # WINDOWS 32bit
    t32api = ctypes.CDLL("./t32api.dll")
    # alternative using windows DLL search order:
#   t32api = ctypes.cdll.t32api
  else:
    # WINDOWS 64bit
    t32api = ctypes.CDLL("./t32api64.dll")
    # alternative using windows DLL search order:
#   t32api = ctypes.cdll.t32api64
elif platform.system()=='Darwin' :
  # Mac OS X
  t32api = ctypes.CDLL("./t32api.dylib")
else :
  if ctypes.sizeof(ctypes.c_voidp)==4:
    # Linux 32bit
    t32api = ctypes.CDLL("./t32api.so")
  else:
    # Linux 64bit
    t32api = ctypes.CDLL("./t32api64.so")

t32api.T32_Config(b"NODE=",b"localhost")
t32api.T32_Config(b"PORT=",b"20000")
t32api.T32_Config(b"PACKLEN=",b"1024")

t32api.T32_Init()
if t32api.T32_Attach(1)!=0:
  print("Failed to connect to TRACE32 PowerView!")
  exit(-1)
t32api.T32_Ping()

t32api.T32_Cmd(b"SYStem.JtagClock 1MHz")
t32api.T32_Cmd(b"SYStem.CONFIG TAPState RunTestIdle")

try:
  jtagInitPrePost(t32api)
  jtagInitAndTAPReset(t32api)
  # just to be sure- disable all SLAVE PORTS -> only JSwitch in the chain
  jswitchWriteReg(t32api, 0x00001, 0xaaaa)
  jswitchWriteReg(t32api, 0x10001, 0xaaaa)
  
  data = jtagInitTAPResetAndIdCodeRead(t32api)
  print("IDCODE is 0x{0:x}".format(int.from_bytes(data, byteorder='little')))
  
  # read ConfigA Register
  data = jswitchReadReg(t32api, 0xf0000)
  
  print("CONFIGA is "+" ".join("{:02x}".format(c) for c in data))
  print("CONFIGA is 0x{0:x}".format(int.from_bytes(data, byteorder='little')))
  
  #enable Port1
  jswitchWriteReg(t32api, 0x1, 0x1)
  #disable Port1
  jswitchWriteReg(t32api, 0x1, 0x2)
except:
  print("Aborting, error while JTAG communication.")

t32api.T32_Exit()
