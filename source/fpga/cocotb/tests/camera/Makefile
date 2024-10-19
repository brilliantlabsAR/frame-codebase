#
# Authored by: Robert Metchev / Raumzeit Technologies (robert@raumzeit.co)
#
# CERN Open Hardware Licence Version 2 - Permissive
#
# Copyright (C) 2024 Robert Metchev
#

TEST_PATH := $(realpath .)
TEST_TOP := camera_test

# JPEG specific setup
ifeq ($(IMG16X16),1)
SENSOR_X_SIZE = 20
SENSOR_Y_SIZE = 20
IMAGE_X_SIZE = 16
IMAGE_Y_SIZE = 16
endif

ifeq ($(IMG512X512),1)
SENSOR_X_SIZE = 520
SENSOR_Y_SIZE = 520
IMAGE_X_SIZE = 512
IMAGE_Y_SIZE = 512
endif

ifeq (1, $(filter 1, $(IMG16X16) $(IMG512X512)))
export SENSOR_X_SIZE := $(SENSOR_X_SIZE)
export SENSOR_Y_SIZE := $(SENSOR_Y_SIZE)
export IMAGE_X_SIZE := $(IMAGE_X_SIZE)
export IMAGE_Y_SIZE := $(IMAGE_Y_SIZE)
endif

ifeq ($(SIM),icarus)
COMPILE_ARGS += $(SENSOR_X_SIZE:%=-DSENSOR_X_SIZE=%) $(SENSOR_Y_SIZE:%=-DSENSOR_Y_SIZE=%)
COMPILE_ARGS += $(IMAGE_X_SIZE:%=-DIMAGE_X_SIZE=%) $(IMAGE_Y_SIZE:%=-DIMAGE_Y_SIZE=%)
COMPILE_ARGS += $(QF0:%=-DQF0=%) $(QF1:%=-DQF1=%) $(QF2:%=-DQF2=%) $(QF3:%=-DQF3=%)
else # verilator + modelsim
EXTRA_ARGS += $(SENSOR_X_SIZE:%=+define+SENSOR_X_SIZE=%) $(SENSOR_Y_SIZE:%=+define+SENSOR_Y_SIZE=%)
EXTRA_ARGS += $(IMAGE_X_SIZE:%=+define+IMAGE_X_SIZE=%) $(IMAGE_Y_SIZE:%=+define+IMAGE_Y_SIZE=%)
EXTRA_ARGS += $(QF0:%=+define+QF0=%) $(QF1:%=+define+QF1=%) $(QF2:%=+define+QF2=%) $(QF3:%=+define+QF3=%)
endif





include $(realpath ../../common/include.mk)

