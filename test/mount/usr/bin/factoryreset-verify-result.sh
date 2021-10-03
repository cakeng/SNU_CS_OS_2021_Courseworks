#!/bin/sh
#
# Copyright (c) 20014- 2017 Samsung Electronics Co., Ltd.
#
# Contact: MyoungJune Park <mj2004.park@samsung.com>
#   Created by Wonil Choi <wonil22.choi@samsung.com>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#




logfile="/opt/var/log/.verify.log"
frlog="/opt/.factoryreset.log"

if [ -e $frlog ]; then
	logfile="$frlog"
fi

/bin/grep "NG," ${logfile}
if [ $? -ne 0 ];then
        exit 0;
else
        exit 1;
fi
