# Copyright Materialize, Inc. and contributors. All rights reserved.
#
# Use of this software is governed by the Business Source License
# included in the LICENSE file at the root of this repository.
#
# As of the Change Date specified in that file, in accordance with
# the Business Source License, use of this software will be governed
# by the Apache License, Version 2.0.

> SELECT DISTINCT mz_sources.name, error
  FROM
      mz_internal.mz_source_status_history
          JOIN mz_sources ON source_id = mz_sources.id
  WHERE
      mz_sources.name =ANY (ARRAY['mz_source', 't1', 'ten'])
          AND
      status = 'stalled';
t1 "postgres: recoverable errors should crash the process during snapshots"
ten "postgres: recoverable errors should crash the process during snapshots"
mz_source "postgres: recoverable errors should crash the process during snapshots"
