# Copyright Materialize, Inc. and contributors. All rights reserved.
#
# Use of this software is governed by the Business Source License
# included in the LICENSE file at the root of this repository.
#
# As of the Change Date specified in that file, in accordance with
# the Business Source License, use of this software will be governed
# by the Apache License, Version 2.0.

$ schema-registry-wait subject=sql-server.test.dbo.transaction_table1-value

> CREATE CONNECTION IF NOT EXISTS kafka_conn TO KAFKA (BROKER '${testdrive.kafka-addr}', SECURITY PROTOCOL PLAINTEXT);

> CREATE SOURCE transaction_table1
  FROM KAFKA CONNECTION kafka_conn (TOPIC 'sql-server.test.dbo.transaction_table1')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY CONNECTION csr_conn
  ENVELOPE DEBEZIUM;

$ schema-registry-wait subject=sql-server.test.dbo.transaction_table2-value

> CREATE CONNECTION IF NOT EXISTS csr_conn TO CONFLUENT SCHEMA REGISTRY (
    URL '${testdrive.schema-registry-url}'
  );

> CREATE SOURCE transaction_table2
  FROM KAFKA CONNECTION kafka_conn (TOPIC 'sql-server.test.dbo.transaction_table2')
  FORMAT AVRO USING CONFLUENT SCHEMA REGISTRY CONNECTION csr_conn
  ENVELOPE DEBEZIUM;

$ sql-server-connect name=sql-server
server=tcp:sql-server,1433;IntegratedSecurity=true;TrustServerCertificate=true;User ID=sa;Password=${arg.sa-password}

$ sql-server-execute name=sql-server
USE test;
BEGIN TRANSACTION INSERT INTO transaction_table1 VALUES ('t1-trans3-event1'); INSERT INTO transaction_table2 VALUES ('t2-trans3-event1'); INSERT INTO transaction_table1 VALUES ('t1-trans3-event2'); INSERT INTO transaction_table2 VALUES ('t2-trans3-event2'); COMMIT;
BEGIN TRANSACTION INSERT INTO transaction_table1 VALUES ('t1-trans4-event1'); INSERT INTO transaction_table2 VALUES ('t2-trans4-event1'); INSERT INTO transaction_table1 VALUES ('t1-trans4-event2'); INSERT INTO transaction_table2 VALUES ('t2-trans4-event2'); COMMIT;

> SELECT * FROM transaction_table1
t1-trans1-event1
t1-trans1-event2
t1-trans2-event1
t1-trans2-event2
t1-trans3-event1
t1-trans3-event2
t1-trans4-event1
t1-trans4-event2

> SELECT * FROm transaction_table2
t2-trans1-event1
t2-trans1-event2
t2-trans2-event1
t2-trans2-event2
t2-trans3-event1
t2-trans3-event2
t2-trans4-event1
t2-trans4-event2
