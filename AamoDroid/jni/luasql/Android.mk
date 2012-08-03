LOCAL_PATH := $(call my-dir)

include $(CLEAR_VARS)

LOCAL_EXPORT_C_INCLUDES := /usr/include
LOCAL_C_INCLUDES += $(LOCAL_PATH)/../lua 

LOCAL_MODULE     := luasql
LOCAL_SRC_FILES  := luasql.c ls_sqlite3.c

LOCAL_STATIC_LIBRARIES := liblua sqlite3

include $(BUILD_SHARED_LIBRARY)
