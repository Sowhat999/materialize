# Copyright Materialize, Inc. and contributors. All rights reserved.
#
# Use of this software is governed by the Business Source License
# included in the LICENSE file at the root of this repository.
#
# As of the Change Date specified in that file, in accordance with
# the Business Source License, use of this software will be governed
# by the Apache License, Version 2.0.

from materialize.mzcompose.composition import Composition, Service
from materialize.mzcompose.services.kafka import Kafka
from materialize.mzcompose.services.zookeeper import Zookeeper

SERVICES = [
    Zookeeper(),
    Kafka(),
    Service(
        name="catalog-compat",
        config={
            "mzbuild": "catcompatck",
        },
    ),
]


def workflow_default(c: Composition) -> None:
    c.up("zookeeper", "kafka")
    c.run("catcompatck")
