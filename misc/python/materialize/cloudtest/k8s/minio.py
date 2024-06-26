# Copyright Materialize, Inc. and contributors. All rights reserved.
#
# Use of this software is governed by the Business Source License
# included in the LICENSE file at the root of this repository.
#
# As of the Change Date specified in that file, in accordance with
# the Business Source License, use of this software will be governed
# by the Apache License, Version 2.0.

from materialize.cloudtest import DEFAULT_K8S_NAMESPACE
from materialize.cloudtest.k8s.api.k8s_resource import K8sResource


class Minio(K8sResource):
    def __init__(
        self,
        namespace: str = DEFAULT_K8S_NAMESPACE,
    ) -> None:
        super().__init__(namespace)

    def create(self) -> None:
        self.kubectl(
            "delete",
            "persistentvolumeclaim",
            "minio-pv-claim",
            "--ignore-not-found",
            "true",
        )

        for yaml in [
            "minio-standalone-pvc",
            "minio-standalone-deployment",
            "minio-standalone-service",
        ]:
            self.kubectl(
                "create",
                "-f",
                f"https://raw.githubusercontent.com/kubernetes/examples/master/staging/storage/minio/{yaml}.yaml",
            )

        self.wait(
            resource="deployment.apps/minio-deployment",
            condition="condition=Available=True",
        )

        self.create_bucket("persist")

    def create_bucket(self, bucket: str) -> None:
        self.kubectl(
            "run",
            "minio",
            "--image=minio/mc",
            "--restart=Never",
            "--command",
            "/bin/sh",
            "--",
            "-c",
            ";".join(
                [
                    f"mc config host add myminio http://minio-service.{self.namespace()}:9000 minio minio123",
                    f"mc rm -r --force myminio/{bucket}",
                    f"mc mb myminio/{bucket}",
                ]
            ),
        )

        self.wait(
            resource="pod/minio",
            condition="jsonpath={.status.containerStatuses[0].state.terminated.reason}=Completed",
        )
