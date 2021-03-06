#ifndef __ACTION_DOUBLEMULT_H__
#define __ACTION_DOUBLEMULT_H__

/*
 * Copyright 2017 International Business Machines
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

#include <stdint.h>
#include <string.h>
#include <ap_int.h>

#include "hls_snap.H"
#include <action_double.h> /* DoubleMult Job definition */

#define RELEASE_LEVEL		0x00000021

#define MAX_NB_OF_DOUBLES_READ	32 //16
#define MAX_NB_OF_WORDS_READ	(MAX_NB_OF_DOUBLES_READ*sizeof(action_datatype_t)/BPERDW) // =2
#define MAX_NB_OF_DOUBLES_PERDW	(BPERDW/sizeof(action_datatype_t)) // =8

typedef char word_t[BPERDW];
//---------------------------------------------------------------------
typedef struct {
	CONTROL Control;	/*  16 bytes */
	doublemult_job_t Data;	/* 108 bytes */
	uint8_t padding[SNAP_HLS_JOBSIZE - sizeof(doublemult_job_t)];
} action_reg;


#endif  /* __ACTION_DOUBLEMULT_H__*/
