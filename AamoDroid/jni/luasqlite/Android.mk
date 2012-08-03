LOCAL_PATH := $(call my-dir)

#####################################################################
#            			sqlite3                                     #
#####################################################################
include $(CLEAR_VARS)
LOCAL_C_INCLUDES := $(LOCAL_PATH)/luasqlite
LOCAL_MODULE	 :=sqlite3
LOCAL_SRC_FILES  :=sqlite3.c

include $(BUILD_STATIC_LIBRARY)

#####################################################################
#            			luaSqlite3                             		#
#####################################################################
include $(CLEAR_VARS)
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../lua
LOCAL_MODULE    := lsqlite
LOCAL_SRC_FILES := lsqlite3.c
LOCAL_LDLIBS	:=-llog -lm

LOCAL_STATIC_LIBRARIES := liblua libsqlite3
include $(BUILD_SHARED_LIBRARY)

