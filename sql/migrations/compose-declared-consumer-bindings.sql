-- compose-declared-consumer-bindings.sql
--
-- K2: remove the invocation-path reads into the SDA capabilities tree. Four
-- installed Port rows name a projected application by a bindingRef that leaves
-- the estate and resolves under
-- scenario-driven-architecture/capabilities/**/projected/application-binding.node.json:
--
--   * bind-gemini-os-credential-port (obtain-governed-model-response)
--   * bind-openai-os-credential-port (obtain-governed-model-response)
--   * classify-inventory-port (operate-tooling-migration-inventory)
--   * resolve-disposition-port (operate-tooling-migration-conveyor)
--
-- The projected application is the documentation the Port must execute. This
-- migration declares it in the Port row itself: the exact binding, execution
-- plan, fixtures and mechanical-sterility documents move into
-- configuration.declaredApplication, and bindingRef/bindingBase are removed.
-- The kernel provider (languages/typescript/runtimes/node/
-- projected-capability-invocation-provider.mjs composing through
-- admitted-consumer-platform.mjs) reads no path for these rows: the plan bytes
-- still hash to the binding's executionPlanDigest, and bindingDigest and
-- capabilityAuthorityDigest are unchanged and still verified before execution.
--
-- Estate-local projected applications (bindingRef under providers/**) keep the
-- file path; only the SDA capability tree leaves the invocation path.
--
-- Idempotent: a replay finds configuration.declaredApplication present and
-- writes no new definition or port version.
--
-- Default: ROLLBACK after verification. Change the final ROLLBACK to COMMIT to install.
SET NOCOUNT ON;
SET XACT_ABORT ON;
DECLARE @trg nvarchar(400), @trgCur CURSOR;
SET @trgCur = CURSOR FOR SELECT QUOTENAME(s.name)+'.'+QUOTENAME(t.name) FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id JOIN sys.schemas s ON s.schema_id=o.schema_id WHERE o.type='U' AND s.name IN ('model','source') AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @trgCur; FETCH NEXT FROM @trgCur INTO @trg; WHILE @@FETCH_STATUS=0 BEGIN EXEC(N'DROP TRIGGER '+@trg); FETCH NEXT FROM @trgCur INTO @trg; END
CLOSE @trgCur; DEALLOCATE @trgCur;
BEGIN TRANSACTION;
GO
-- =====================================================================
-- Declared application documents (exact projected bytes).
-- =====================================================================
DECLARE @os_credential_binding_document nvarchar(max)=N'{
  "bindingType": "projected-consumer-application-binding.v2",
  "executionPlan": "execution-plans/consumer-execution-plan.node.json",
  "executionPlanDigest": "sha256:6da36d898b9400239914f62d06ccd8cf6f491210daa35ab55a7d4dda5c22fbc2",
  "fixtures": "fixtures/fixtures.json",
  "mechanicalSterility": "projection-conformance.json"
}
';
DECLARE @os_credential_plan_document nvarchar(max)=N'{
  "executionEmbodimentPlanType": "consumer-execution-embodiment-plan.v2",
  "target": "node",
  "capabilityId": "bind-os-environment-credential",
  "source": {
    "queryType": "projected-consumer-conformance-query.v1",
    "queryId": "scenario-conformance-closure",
    "queryDigest": "sha256:c4963e2b295c34d38ec5a1769ba482e53fe4fd5fdde782cd4cba7f738447d305",
    "capabilityAuthorityDigest": "sha256:1d7326341cd673df1e960584f101bcc722705f50df08aa856a6dd45649e5d079",
    "mechanicResolutionDigest": "sha256:1546d9bf9a33116753adefee2f122153945329c9efd9d2f3b1d78cbb869146ed"
  },
  "rootNodeId": "bind-os-environment-credential",
  "nodes": [
    {
      "nodeId": "bind-os-environment-credential",
      "scenario": {
        "scenarioId": "bind-os-environment-credential",
        "input": {
          "inputId": "os-environment-credential-binding-request",
          "contract": {
            "contractId": "os-environment-credential-binding-request.v1"
          }
        },
        "event": {
          "eventId": "os-environment-credential-binding-requested",
          "executionAuthorityId": "bind-os-environment-credential.v1"
        },
        "outcome": {
          "outcomeId": "os-environment-credential-binding",
          "contract": {
            "contractId": "os-environment-credential-binding-evidence.v1"
          },
          "terminal": true
        }
      },
      "operations": [
        {
          "operationId": "bind-os-environment-credential.operation.1",
          "kind": "invoke-port",
          "mechanicBindingId": "port:bind-os-credential-port"
        },
        {
          "operationId": "bind-os-environment-credential.operation.2",
          "kind": "invoke-scenario",
          "scenarioNodeId": "hold-missing-os-environment-credential"
        },
        {
          "operationId": "bind-os-environment-credential.operation.3",
          "kind": "invoke-scenario",
          "scenarioNodeId": "reject-unauthorized-os-environment-credential-reference"
        }
      ],
      "transition": null
    },
    {
      "nodeId": "hold-missing-os-environment-credential",
      "scenario": {
        "scenarioId": "hold-missing-os-environment-credential",
        "input": {
          "inputId": "os-environment-credential-binding-request",
          "contract": {
            "contractId": "os-environment-credential-binding-request.v1"
          }
        },
        "event": {
          "eventId": "missing-os-environment-credential-binding-requested",
          "executionAuthorityId": "hold-missing-os-environment-credential.v1"
        },
        "outcome": {
          "outcomeId": "os-environment-credential-not-available",
          "contract": {
            "contractId": "os-environment-credential-binding-evidence.v1"
          },
          "terminal": true
        }
      },
      "operations": [
        {
          "operationId": "hold-missing-os-environment-credential.operation.1",
          "kind": "invoke-port",
          "mechanicBindingId": "port:preserve-os-credential-evidence-port"
        }
      ],
      "transition": null
    },
    {
      "nodeId": "reject-unauthorized-os-environment-credential-reference",
      "scenario": {
        "scenarioId": "reject-unauthorized-os-environment-credential-reference",
        "input": {
          "inputId": "os-environment-credential-binding-request",
          "contract": {
            "contractId": "os-environment-credential-binding-request.v1"
          }
        },
        "event": {
          "eventId": "unauthorized-os-environment-credential-binding-requested",
          "executionAuthorityId": "reject-unauthorized-os-environment-credential-reference.v1"
        },
        "outcome": {
          "outcomeId": "os-environment-credential-not-available",
          "contract": {
            "contractId": "os-environment-credential-binding-evidence.v1"
          },
          "terminal": true
        }
      },
      "operations": [
        {
          "operationId": "reject-unauthorized-os-environment-credential-reference.operation.1",
          "kind": "invoke-port",
          "mechanicBindingId": "port:preserve-os-credential-evidence-port"
        }
      ],
      "transition": null
    }
  ],
  "compositionPolicy": {
    "carrierMode": "previous-admitted-outcome",
    "contractAdmissionMode": "each-scenario-boundary",
    "lineageMode": "retain-root-and-parent-execution",
    "failureMode": "stop-at-first-non-success",
    "cycleMode": "reject-recursive-invocation"
  },
  "mechanicBindings": [
    {
      "bindingId": "contract-admission",
      "mechanicType": "contract-admission",
      "providerCapabilityId": "sda-schema-contract-admission.v1",
      "provider": "ScenarioKernel.NodePlatform.Schema.JsonSchemaContractAdmission",
      "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
      "configuration": {
        "contractAuthorities": {
          "authorityType": "consumer-contract-authorities.v1",
          "contracts": {
            "os-environment-credential-binding-request.v1": {
              "schemaRef": "input.schema.json",
              "schemaId": "https://schemas.scenario-driven.dev/sda-platform/os-environment-credential-binding-request.v1.schema.json",
              "schemaDigest": "f016c249286c0213a8ea238e285f23b5919bb8a6458ef0785b3ba4637778253b",
              "schema": {
                "$schema": "https://json-schema.org/draft/2020-12/schema",
                "$id": "https://schemas.scenario-driven.dev/sda-platform/os-environment-credential-binding-request.v1.schema.json",
                "title": "OS environment credential binding request v1",
                "anyOf": [
                  {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "contractId",
                      "credentialReference",
                      "invocationIdentity",
                      "requestingCapabilityId",
                      "endpointAuthorityDigest",
                      "effectScope"
                    ],
                    "properties": {
                      "contractId": {
                        "const": "os-environment-credential-binding-request.v1"
                      },
                      "credentialReference": {
                        "type": "string",
                        "pattern": "^[A-Za-z0-9_-]+$"
                      },
                      "invocationIdentity": {
                        "type": "string",
                        "minLength": 1
                      },
                      "requestingCapabilityId": {
                        "type": "string",
                        "minLength": 1
                      },
                      "endpointAuthorityDigest": {
                        "type": "string",
                        "pattern": "^sha256:[a-f0-9]{64}$"
                      },
                      "effectScope": {
                        "type": "string",
                        "minLength": 1
                      }
                    }
                  },
                  {
                    "type": "object",
                    "required": [
                      "contractId",
                      "disposition",
                      "opaqueBindingId",
                      "nonDisclosureVerified"
                    ],
                    "properties": {
                      "contractId": {
                        "const": "os-environment-credential-binding-evidence.v1"
                      },
                      "disposition": {
                        "type": "string"
                      },
                      "opaqueBindingId": {
                        "type": "string"
                      },
                      "nonDisclosureVerified": {
                        "const": true
                      }
                    }
                  }
                ]
              }
            },
            "os-environment-credential-binding-evidence.v1": {
              "schemaRef": "outcome.schema.json",
              "schemaId": "https://schemas.scenario-driven.dev/sda-platform/os-environment-credential-binding-evidence.v1.schema.json",
              "schemaDigest": "4b4507fca6a63a4c2a5360f57209418177877696875e7a2864b0ade4ca2e4dfb",
              "schema": {
                "$schema": "https://json-schema.org/draft/2020-12/schema",
                "$id": "https://schemas.scenario-driven.dev/sda-platform/os-environment-credential-binding-evidence.v1.schema.json",
                "title": "OS environment credential binding evidence v1",
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "contractId",
                  "disposition",
                  "opaqueBindingId",
                  "referenceName",
                  "invocationIdentity",
                  "requestingCapabilityId",
                  "endpointAuthorityDigest",
                  "resolutionScope",
                  "credentialInjectionRuleId",
                  "nonDisclosureVerified",
                  "effectLineage"
                ],
                "properties": {
                  "contractId": {
                    "const": "os-environment-credential-binding-evidence.v1"
                  },
                  "disposition": {
                    "enum": [
                      "BOUND",
                      "CREDENTIAL_NOT_AVAILABLE",
                      "UNAUTHORIZED_REFERENCE",
                      "IDENTITY_MISMATCH"
                    ]
                  },
                  "opaqueBindingId": {
                    "type": "string",
                    "minLength": 1
                  },
                  "referenceName": {
                    "type": "string",
                    "pattern": "^[A-Za-z0-9_-]+$"
                  },
                  "invocationIdentity": {
                    "type": "string",
                    "minLength": 1
                  },
                  "requestingCapabilityId": {
                    "type": "string",
                    "minLength": 1
                  },
                  "endpointAuthorityDigest": {
                    "type": [
                      "string",
                      "null"
                    ],
                    "pattern": "^(sha256:[a-f0-9]{64}|null)$"
                  },
                  "resolutionScope": {
                    "enum": [
                      "PROCESS_ENVIRONMENT",
                      "OS_USER_SCOPE",
                      "OS_MACHINE_SCOPE",
                      "NONE"
                    ]
                  },
                  "credentialInjectionRuleId": {
                    "type": "string",
                    "minLength": 1
                  },
                  "nonDisclosureVerified": {
                    "const": true
                  },
                  "effectLineage": {
                    "type": "array",
                    "items": {
                      "type": "string"
                    }
                  }
                }
              }
            }
          }
        }
      }
    },
    {
      "bindingId": "port:bind-os-credential-port",
      "mechanicType": "event-port",
      "providerCapabilityId": "sda-os-environment-credential-port.v1",
      "provider": "ScenarioKernel.NodePlatform.Effects.OsEnvironmentCredentialBinding",
      "implementationRef": "languages/typescript/runtimes/node/os-environment-credential-provider.mjs",
      "configuration": {
        "credentialAuthorities": [
          {
            "referenceName": "LOC_GEMINI_API_KEY",
            "requestingCapabilityIds": [
              "execute-governed-model-invocation",
              "obtain-governed-model-response",
              "author-tooling-capability-candidate",
              "execute-projected-model-provider-attempt"
            ],
            "endpointAuthorityDigests": [
              "sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04"
            ],
            "effectScopes": [
              "governed-model-invocation"
            ],
            "injectionRule": {
              "id": "gemini-x-goog-api-key.v1",
              "headerName": "x-goog-api-key"
            },
            "lifetimeMilliseconds": 120000
          },
          {
            "referenceName": "LOC_OPENAI_API_KEY",
            "requestingCapabilityIds": [
              "execute-governed-model-invocation",
              "obtain-governed-model-response",
              "author-tooling-capability-candidate",
              "execute-projected-model-provider-attempt"
            ],
            "endpointAuthorityDigests": [
              "sha256:b70b8bc81f93ef949d7ae6cabbf71a56b4af2440c5489c5c4037923b534f0109"
            ],
            "effectScopes": [
              "governed-model-invocation"
            ],
            "injectionRule": {
              "id": "openai-bearer-authorization.v1",
              "headerName": "authorization"
            },
            "lifetimeMilliseconds": 120000
          },
          {
            "referenceName": "SIDEFX_ABSENT_TEST_CREDENTIAL",
            "requestingCapabilityIds": [
              "execute-governed-model-invocation"
            ],
            "endpointAuthorityDigests": [
              "sha256:0000000000000000000000000000000000000000000000000000000000000000"
            ],
            "effectScopes": [
              "governed-model-invocation"
            ],
            "injectionRule": {
              "id": "absent-test-credential.v1",
              "headerName": "x-test-credential"
            },
            "lifetimeMilliseconds": 120000
          }
        ]
      }
    },
    {
      "bindingId": "port:preserve-os-credential-evidence-port",
      "mechanicType": "event-port",
      "providerCapabilityId": "sda-authority-transformation-port.v1",
      "provider": "ScenarioKernel.NodePlatform.Execution.AuthorityTransformation",
      "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
      "configuration": {
        "expression": {
          "op": "path",
          "from": "input",
          "path": ""
        }
      }
    }
  ],
  "conformance": {
    "queryId": "scenario-conformance-closure",
    "platformMechanics": {
      "resolutionType": "consumer-platform-mechanic-resolution.v1",
      "projectionTarget": "node",
      "requirements": [
        {
          "mechanicId": "contract-document-reading",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "canonicalization",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "schema-admission",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "authority-resolution",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "semantic-execution",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "telemetry-observation",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "scenario-invocation",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "transition-binding-projection",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "interface-delivery",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "runtime-projection",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "artifact-result-delivery",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "authority-driven-transformation",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "durable-artifact-materialization",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "contract-validation",
          "capabilityKind": "contract-validator",
          "requiredBy": "scenario-contract-admission",
          "requestedCapabilityId": "sda-schema-contract-admission.v1"
        },
        {
          "mechanicId": "cli-delivery",
          "capabilityKind": "interface-delivery",
          "requiredBy": "interface:bind-os-environment-credential-cli",
          "requestedCapabilityId": "sda-json-cli.v1"
        },
        {
          "mechanicId": "json-reading",
          "capabilityKind": "interface-delivery",
          "requiredBy": "interface:bind-os-environment-credential-cli",
          "requestedCapabilityId": "sda-json-cli.v1"
        },
        {
          "mechanicId": "json-serialization",
          "capabilityKind": "interface-delivery",
          "requiredBy": "interface:bind-os-environment-credential-cli",
          "requestedCapabilityId": "sda-json-cli.v1"
        },
        {
          "mechanicId": "event-port-invocation",
          "capabilityKind": "event-port",
          "requiredBy": "port:bind-os-credential-port",
          "requestedCapabilityId": "sda-os-environment-credential-port.v1"
        },
        {
          "mechanicId": "event-port-invocation",
          "capabilityKind": "event-port",
          "requiredBy": "port:preserve-os-credential-evidence-port",
          "requestedCapabilityId": "sda-authority-transformation-port.v1"
        }
      ],
      "resolutions": [
        {
          "mechanicId": "contract-document-reading",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "canonicalization",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "schema-admission",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "authority-resolution",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "semantic-execution",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "telemetry-observation",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "scenario-invocation",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "transition-binding-projection",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "interface-delivery",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "runtime-projection",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "artifact-result-delivery",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "authority-driven-transformation",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "durable-artifact-materialization",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "contract-validation",
          "capabilityKind": "contract-validator",
          "requiredBy": "scenario-contract-admission",
          "requestedCapabilityId": "sda-schema-contract-admission.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-schema-contract-admission.v1",
          "provider": "ScenarioKernel.NodePlatform.Schema.JsonSchemaContractAdmission",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "cli-delivery",
          "capabilityKind": "interface-delivery",
          "requiredBy": "interface:bind-os-environment-credential-cli",
          "requestedCapabilityId": "sda-json-cli.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-json-cli.v1",
          "provider": "ScenarioKernel.NodePlatform.Interface.JsonCli",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "json-reading",
          "capabilityKind": "interface-delivery",
          "requiredBy": "interface:bind-os-environment-credential-cli",
          "requestedCapabilityId": "sda-json-cli.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-json-cli.v1",
          "provider": "ScenarioKernel.NodePlatform.Interface.JsonCli",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "json-serialization",
          "capabilityKind": "interface-delivery",
          "requiredBy": "interface:bind-os-environment-credential-cli",
          "requestedCapabilityId": "sda-json-cli.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-json-cli.v1",
          "provider": "ScenarioKernel.NodePlatform.Interface.JsonCli",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "event-port-invocation",
          "capabilityKind": "event-port",
          "requiredBy": "port:bind-os-credential-port",
          "requestedCapabilityId": "sda-os-environment-credential-port.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-os-environment-credential-port.v1",
          "provider": "ScenarioKernel.NodePlatform.Effects.OsEnvironmentCredentialBinding",
          "implementationRef": "languages/typescript/runtimes/node/os-environment-credential-provider.mjs",
          "conformanceRef": "tools/tests/conformance/os-environment-credential.test.js"
        },
        {
          "mechanicId": "event-port-invocation",
          "capabilityKind": "event-port",
          "requiredBy": "port:preserve-os-credential-evidence-port",
          "requestedCapabilityId": "sda-authority-transformation-port.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-authority-transformation-port.v1",
          "provider": "ScenarioKernel.NodePlatform.Execution.AuthorityTransformation",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        }
      ],
      "disposition": "RESOLVED"
    },
    "executableOrigin": {
      "originType": "consumer-executable-origin.v1",
      "disposition": "PROJECTED_ONLY",
      "unauthorizedFiles": []
    },
    "closures": [
      {
        "closureId": "feature-to-scenario",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "scenario-to-contract",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "scenario-to-event-authority",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "outcome-to-transition",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "transition-to-next-input",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "scenario-to-interface",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "execution-to-telemetry",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "scenario-to-projection",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "expected-to-observed-execution",
        "evaluation": "runtime-evidence",
        "evaluatorId": "expected-execution-trace.v1",
        "configuration": {
          "expectedTelemetry": {
            "traceType": "projected-expected-consumer-trace.v1",
            "telemetryId": "consumer-scenario-execution-telemetry",
            "capabilityId": "bind-os-environment-credential",
            "rootScenarioId": "bind-os-environment-credential",
            "observationType": "scenario-execution-observation.v1",
            "lineageFields": [
              "executionId",
              "rootExecutionId",
              "parentExecutionId",
              "scenarioId"
            ],
            "scenarios": [
              {
                "scenarioId": "bind-os-environment-credential",
                "steps": [
                  "admit-input",
                  "resolve-event-authority",
                  "execute-event-authority",
                  "admit-outcome",
                  "resolve-disposition"
                ],
                "expectedTransitionId": null
              },
              {
                "scenarioId": "hold-missing-os-environment-credential",
                "steps": [
                  "admit-input",
                  "resolve-event-authority",
                  "execute-event-authority",
                  "admit-outcome",
                  "resolve-disposition"
                ],
                "expectedTransitionId": null
              },
              {
                "scenarioId": "reject-unauthorized-os-environment-credential-reference",
                "steps": [
                  "admit-input",
                  "resolve-event-authority",
                  "execute-event-authority",
                  "admit-outcome",
                  "resolve-disposition"
                ],
                "expectedTransitionId": null
              }
            ]
          }
        }
      },
      {
        "closureId": "root-to-terminal-behavior",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "required-mechanic-to-platform-capability",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "consumer-executable-origin",
        "evaluation": "runtime-evidence",
        "evaluatorId": "projected-origin-observation.v1",
        "configuration": {
          "requiredDisposition": "PURE_PROJECTION_CONFORMS"
        }
      },
      {
        "closureId": "dynamic-semantic-execution",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "domain-contract-admission",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      }
    ]
  },
  "requiredProviderCapabilityIds": [
    "sda-authority-transformation-port.v1",
    "sda-os-environment-credential-port.v1",
    "sda-schema-contract-admission.v1"
  ]
}
';
DECLARE @os_credential_fixtures_document nvarchar(max)=N'{
  "fixtureType": "consumer-capability-fixtures.v1",
  "fixtures": [
    {
      "fixtureId": "reject-undeclared-reference-without-reading",
      "input": {
        "contractId": "os-environment-credential-binding-request.v1",
        "credentialReference": "UNDECLARED_TEST_REFERENCE",
        "invocationIdentity": "invocation-test-1",
        "requestingCapabilityId": "obtain-governed-model-response",
        "endpointAuthorityDigest": "sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04",
        "effectScope": "governed-model-invocation"
      },
      "portOutcomes": {
        "authority-driven-composition": {
          "authority": "interfaces.authority.json"
        }
      },
      "expected": {
        "disposition": "terminated",
        "terminalScenarioId": "bind-os-environment-credential",
        "scenarioSequence": [
          "bind-os-environment-credential"
        ],
        "outcomeAssertions": [
          {
            "conditionId": "unauthorized-refused",
            "path": "disposition",
            "operator": "equals",
            "value": "UNAUTHORIZED_REFERENCE"
          },
          {
            "conditionId": "no-binding-created",
            "path": "opaqueBindingId",
            "operator": "equals",
            "value": "none"
          },
          {
            "conditionId": "non-disclosure-preserved",
            "path": "nonDisclosureVerified",
            "operator": "equals",
            "value": true
          }
        ]
      }
    },
    {
      "fixtureId": "reject-identity-mismatch",
      "input": {
        "contractId": "os-environment-credential-binding-request.v1",
        "credentialReference": "LOC_GEMINI_API_KEY",
        "invocationIdentity": "invocation-test-2",
        "requestingCapabilityId": "unrelated-capability",
        "endpointAuthorityDigest": "sha256:57ab352b0978dca5e5ce33a28ccd7027c20df96da4138dbc7e8088f7c8fb0c04",
        "effectScope": "governed-model-invocation"
      },
      "portOutcomes": {
        "authority-driven-composition": {
          "authority": "interfaces.authority.json"
        }
      },
      "expected": {
        "disposition": "terminated",
        "terminalScenarioId": "bind-os-environment-credential",
        "scenarioSequence": [
          "bind-os-environment-credential"
        ],
        "outcomeAssertions": [
          {
            "conditionId": "identity-mismatch-refused",
            "path": "disposition",
            "operator": "equals",
            "value": "IDENTITY_MISMATCH"
          },
          {
            "conditionId": "no-binding-created",
            "path": "opaqueBindingId",
            "operator": "equals",
            "value": "none"
          },
          {
            "conditionId": "non-disclosure-preserved",
            "path": "nonDisclosureVerified",
            "operator": "equals",
            "value": true
          }
        ]
      }
    },
    {
      "fixtureId": "hold-absent-declared-reference",
      "input": {
        "contractId": "os-environment-credential-binding-request.v1",
        "credentialReference": "SIDEFX_ABSENT_TEST_CREDENTIAL",
        "invocationIdentity": "invocation-test-3",
        "requestingCapabilityId": "execute-governed-model-invocation",
        "endpointAuthorityDigest": "sha256:0000000000000000000000000000000000000000000000000000000000000000",
        "effectScope": "governed-model-invocation"
      },
      "portOutcomes": {
        "authority-driven-composition": {
          "authority": "interfaces.authority.json"
        }
      },
      "expected": {
        "disposition": "terminated",
        "terminalScenarioId": "bind-os-environment-credential",
        "scenarioSequence": [
          "bind-os-environment-credential"
        ],
        "outcomeAssertions": [
          {
            "conditionId": "absence-held",
            "path": "disposition",
            "operator": "equals",
            "value": "CREDENTIAL_NOT_AVAILABLE"
          },
          {
            "conditionId": "no-binding-created",
            "path": "opaqueBindingId",
            "operator": "equals",
            "value": "none"
          },
          {
            "conditionId": "no-scope-invented",
            "path": "resolutionScope",
            "operator": "equals",
            "value": "NONE"
          },
          {
            "conditionId": "non-disclosure-preserved",
            "path": "nonDisclosureVerified",
            "operator": "equals",
            "value": true
          }
        ]
      }
    }
  ]
}
';
DECLARE @os_credential_sterility_document nvarchar(max)=N'{
  "conformanceType": "projected-artifact-mechanical-sterility.v1",
  "sourceOrigin": "PROJECTED",
  "forbiddenExecutableMechanics": {
    "branch": 0,
    "iteration": 0,
    "exception-handling": 0,
    "throw": 0,
    "object-construction": 0,
    "serialization": 0,
    "normalization": 0,
    "validation": 0,
    "fallback": 0,
    "retry": 0,
    "state-mutation": 0,
    "meaning-hidden-in-text": 0
  },
  "violations": [],
  "disposition": "PURE_PROJECTION_CONFORMS"
}
';
DECLARE @os_credential_declared_application nvarchar(max)=N'{"bindingDocument":' + N'"' + STRING_ESCAPE(@os_credential_binding_document,'json') + N'"' + N',"executionPlanDocument":' + N'"' + STRING_ESCAPE(@os_credential_plan_document,'json') + N'"' + N',"fixturesDocument":' + N'"' + STRING_ESCAPE(@os_credential_fixtures_document,'json') + N'"' + N',"mechanicalSterilityDocument":' + N'"' + STRING_ESCAPE(@os_credential_sterility_document,'json') + N'"' + N'}';

DECLARE @tooling_decision_binding_document nvarchar(max)=N'{
  "bindingType": "projected-consumer-application-binding.v2",
  "executionPlan": "execution-plans/consumer-execution-plan.node.json",
  "executionPlanDigest": "sha256:f88e02a00493eaef43b42e343a39117bb60ba7eed52111f4f30a4de773c3244b",
  "fixtures": "fixtures/fixtures.json",
  "mechanicalSterility": "projection-conformance.json"
}
';
DECLARE @tooling_decision_plan_document nvarchar(max)=N'{
  "executionEmbodimentPlanType": "consumer-execution-embodiment-plan.v1",
  "target": "node",
  "capabilityId": "decide-tooling-migration",
  "source": {
    "queryType": "projected-consumer-conformance-query.v1",
    "queryId": "scenario-conformance-closure",
    "queryDigest": "sha256:0b94fa7d02211417328b6395134e84fefd7c40cdefb3d4117feaa9c9b9b33e53",
    "capabilityAuthorityDigest": "sha256:1a513b6a90557a2f989f644cabebfdabbd24f7f2aac3e8deb4a4d26ac6ba7a1f",
    "mechanicResolutionDigest": "sha256:d277d2c469a206761b7a6b2de468b30f837540057c5228efbbd6b796e42275e0"
  },
  "rootNodeId": "decide-tooling-migration",
  "nodes": [
    {
      "nodeId": "decide-tooling-migration",
      "scenario": {
        "scenarioId": "decide-tooling-migration",
        "input": {
          "inputId": "tooling-migration-facts",
          "contract": {
            "contractId": "tooling-migration-decision-input.v1"
          }
        },
        "event": {
          "eventId": "tooling-migration-decision-requested",
          "executionAuthorityId": "tooling-migration-decision.v1"
        },
        "outcome": {
          "outcomeId": "tooling-migration-decision-known",
          "contract": {
            "contractId": "tooling-migration-decision.v1"
          },
          "terminal": true
        }
      },
      "operations": [
        {
          "operationId": "decide-tooling-migration.operation.1",
          "mechanicBindingId": "port:decide-tooling-migration"
        }
      ],
      "transition": null
    }
  ],
  "mechanicBindings": [
    {
      "bindingId": "contract-admission",
      "mechanicType": "contract-admission",
      "providerCapabilityId": "sda-schema-contract-admission.v1",
      "provider": "ScenarioKernel.NodePlatform.Schema.JsonSchemaContractAdmission",
      "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
      "configuration": {
        "contractAuthorities": {
          "authorityType": "consumer-contract-authorities.v1",
          "contracts": {
            "tooling-migration-decision-input.v1": {
              "schemaRef": "../../../tooling-migration-conveyor/contracts/tooling-migration-decision-input.v1.schema.json",
              "schemaId": "https://schemas.scenario-driven.dev/tooling/tooling-migration-decision-input.v1.schema.json",
              "schemaDigest": "92b6fe1c58d76177807f863269560ae43e51b390a7e61902d65155aaeba8c6da",
              "schema": {
                "$schema": "https://json-schema.org/draft/2020-12/schema",
                "$id": "https://schemas.scenario-driven.dev/tooling/tooling-migration-decision-input.v1.schema.json",
                "title": "Tooling Migration Decision Input",
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "decisionType",
                  "candidates",
                  "bindingDocument",
                  "capability",
                  "gateExitCode",
                  "promote",
                  "verificationPassed",
                  "runResults"
                ],
                "properties": {
                  "decisionType": {
                    "enum": [
                      "CLASSIFY_INVENTORY",
                      "PLAN_BINDING_REPLACEMENT",
                      "EVALUATE_GATE",
                      "DETERMINE_EVIDENCE_DISPOSITION",
                      "FINALIZE_RUN"
                    ]
                  },
                  "candidates": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "additionalProperties": false,
                      "required": [
                        "capabilityId",
                        "groupId",
                        "responsibilityId",
                        "providerId",
                        "protocol",
                        "featureRef",
                        "workspaceRef",
                        "featureExists",
                        "workspaceExists"
                      ],
                      "properties": {
                        "capabilityId": {
                          "type": "string",
                          "minLength": 1
                        },
                        "groupId": {
                          "type": "string",
                          "minLength": 1
                        },
                        "responsibilityId": {
                          "type": "string",
                          "minLength": 1
                        },
                        "providerId": {
                          "type": [
                            "string",
                            "null"
                          ]
                        },
                        "protocol": {
                          "type": "string",
                          "minLength": 1
                        },
                        "featureRef": {
                          "type": "string",
                          "minLength": 1
                        },
                        "workspaceRef": {
                          "type": "string",
                          "minLength": 1
                        },
                        "featureExists": {
                          "type": "boolean"
                        },
                        "workspaceExists": {
                          "type": "boolean"
                        }
                      }
                    }
                  },
                  "bindingDocument": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "bindingType",
                      "bindings"
                    ],
                    "properties": {
                      "bindingType": {
                        "const": "responsibility-provider-bindings.v1"
                      },
                      "bindings": {
                        "type": "array",
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "responsibilityId",
                            "providerId",
                            "implementationRef",
                            "requires"
                          ],
                          "properties": {
                            "responsibilityId": {
                              "type": "string",
                              "minLength": 1
                            },
                            "providerId": {
                              "type": "string",
                              "minLength": 1
                            },
                            "implementationRef": {
                              "type": "string",
                              "minLength": 1
                            },
                            "requires": {
                              "type": "array",
                              "items": {
                                "type": "string"
                              }
                            },
                            "protocol": {
                              "type": "string",
                              "minLength": 1
                            }
                          }
                        }
                      }
                    }
                  },
                  "capability": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "responsibilityId",
                      "replacement"
                    ],
                    "properties": {
                      "responsibilityId": {
                        "type": "string",
                        "minLength": 1
                      },
                      "replacement": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "providerId",
                          "implementationRef",
                          "protocol"
                        ],
                        "properties": {
                          "providerId": {
                            "type": "string",
                            "minLength": 1
                          },
                          "implementationRef": {
                            "type": "string",
                            "minLength": 1
                          },
                          "protocol": {
                            "const": "projected-consumer-runtime-v2"
                          }
                        }
                      }
                    }
                  },
                  "gateExitCode": {
                    "type": "integer"
                  },
                  "promote": {
                    "type": "boolean"
                  },
                  "verificationPassed": {
                    "type": "boolean"
                  },
                  "runResults": {
                    "type": "array",
                    "items": {
                      "type": "object",
                      "additionalProperties": false,
                      "required": [
                        "capabilityId",
                        "disposition"
                      ],
                      "properties": {
                        "capabilityId": {
                          "type": "string",
                          "minLength": 1
                        },
                        "disposition": {
                          "enum": [
                            "PROMOTED",
                            "REJECTED"
                          ]
                        }
                      }
                    }
                  }
                }
              }
            },
            "tooling-migration-decision.v1": {
              "schemaRef": "../../../tooling-migration-conveyor/contracts/tooling-migration-decision.v1.schema.json",
              "schemaId": "https://schemas.scenario-driven.dev/tooling/tooling-migration-decision.v1.schema.json",
              "schemaDigest": "a27dcf91457f0b480a02c6bd82aa8b7c88175eec018d336d7f8c5d1e6ac1536c",
              "schema": {
                "$schema": "https://json-schema.org/draft/2020-12/schema",
                "$id": "https://schemas.scenario-driven.dev/tooling/tooling-migration-decision.v1.schema.json",
                "title": "Tooling Migration Decision",
                "type": "object",
                "additionalProperties": false,
                "required": [
                  "decisionType"
                ],
                "properties": {
                  "decisionType": {
                    "enum": [
                      "CLASSIFY_INVENTORY",
                      "PLAN_BINDING_REPLACEMENT",
                      "EVALUATE_GATE",
                      "DETERMINE_EVIDENCE_DISPOSITION",
                      "FINALIZE_RUN"
                    ]
                  },
                  "inventory": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "inventoryType",
                      "entries",
                      "summary"
                    ],
                    "properties": {
                      "inventoryType": {
                        "const": "tooling-projection-migration-inventory.v1"
                      },
                      "entries": {
                        "type": "array",
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "capabilityId",
                            "groupId",
                            "responsibilityId",
                            "providerId",
                            "protocol",
                            "featureRef",
                            "workspaceRef",
                            "state"
                          ],
                          "properties": {
                            "capabilityId": {
                              "type": "string"
                            },
                            "groupId": {
                              "type": "string"
                            },
                            "responsibilityId": {
                              "type": "string"
                            },
                            "providerId": {
                              "type": [
                                "string",
                                "null"
                              ]
                            },
                            "protocol": {
                              "type": "string"
                            },
                            "featureRef": {
                              "type": "string"
                            },
                            "workspaceRef": {
                              "type": "string"
                            },
                            "state": {
                              "enum": [
                                "FEATURE_REQUIRED",
                                "WORKSPACE_REQUIRED",
                                "CANDIDATE_READY",
                                "PROMOTED"
                              ]
                            }
                          }
                        }
                      },
                      "summary": {
                        "type": "object",
                        "additionalProperties": false,
                        "required": [
                          "FEATURE_REQUIRED",
                          "WORKSPACE_REQUIRED",
                          "CANDIDATE_READY",
                          "PROMOTED"
                        ],
                        "properties": {
                          "FEATURE_REQUIRED": {
                            "type": "integer",
                            "minimum": 0
                          },
                          "WORKSPACE_REQUIRED": {
                            "type": "integer",
                            "minimum": 0
                          },
                          "CANDIDATE_READY": {
                            "type": "integer",
                            "minimum": 0
                          },
                          "PROMOTED": {
                            "type": "integer",
                            "minimum": 0
                          }
                        }
                      }
                    }
                  },
                  "replacementDocument": {
                    "type": "object",
                    "additionalProperties": false,
                    "required": [
                      "bindingType",
                      "bindings"
                    ],
                    "properties": {
                      "bindingType": {
                        "const": "responsibility-provider-bindings.v1"
                      },
                      "bindings": {
                        "type": "array",
                        "items": {
                          "type": "object",
                          "additionalProperties": false,
                          "required": [
                            "responsibilityId",
                            "providerId",
                            "implementationRef",
                            "requires"
                          ],
                          "properties": {
                            "responsibilityId": {
                              "type": "string"
                            },
                            "providerId": {
                              "type": "string"
                            },
                            "implementationRef": {
                              "type": "string"
                            },
                            "requires": {
                              "type": "array",
                              "items": {
                                "type": "string"
                              }
                            },
                            "protocol": {
                              "type": "string"
                            }
                          }
                        }
                      }
                    }
                  },
                  "promotionDisposition": {
                    "enum": [
                      "PROMOTED",
                      "ROLLED_BACK"
                    ]
                  },
                  "bindingAction": {
                    "enum": [
                      "KEEP_REPLACEMENT",
                      "RESTORE_ORIGINAL"
                    ]
                  },
                  "evidenceDisposition": {
                    "enum": [
                      "VERIFIED",
                      "PROMOTED",
                      "REJECTED"
                    ]
                  },
                  "runDisposition": {
                    "enum": [
                      "COMPLETED",
                      "COMPLETED_WITH_REJECTIONS"
                    ]
                  },
                  "continueIndependentCandidates": {
                    "type": "boolean"
                  }
                }
              }
            }
          }
        }
      }
    },
    {
      "bindingId": "port:decide-tooling-migration",
      "mechanicType": "event-port",
      "providerCapabilityId": "sda-authority-transformation-port.v1",
      "provider": "ScenarioKernel.NodePlatform.Execution.AuthorityTransformation",
      "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
      "configuration": {
        "expression": {
          "op": "if",
          "when": {
            "op": "equals",
            "left": {
              "op": "path",
              "from": "input",
              "path": "decisionType"
            },
            "right": {
              "op": "literal",
              "value": "CLASSIFY_INVENTORY"
            }
          },
          "then": {
            "op": "let",
            "bindings": {
              "classifiedEntries": {
                "op": "map",
                "from": {
                  "op": "path",
                  "from": "input",
                  "path": "candidates"
                },
                "as": "candidate",
                "value": {
                  "op": "object",
                  "fields": {
                    "capabilityId": {
                      "op": "path",
                      "from": "candidate",
                      "path": "capabilityId"
                    },
                    "groupId": {
                      "op": "path",
                      "from": "candidate",
                      "path": "groupId"
                    },
                    "responsibilityId": {
                      "op": "path",
                      "from": "candidate",
                      "path": "responsibilityId"
                    },
                    "providerId": {
                      "op": "path",
                      "from": "candidate",
                      "path": "providerId"
                    },
                    "protocol": {
                      "op": "path",
                      "from": "candidate",
                      "path": "protocol"
                    },
                    "featureRef": {
                      "op": "path",
                      "from": "candidate",
                      "path": "featureRef"
                    },
                    "workspaceRef": {
                      "op": "path",
                      "from": "candidate",
                      "path": "workspaceRef"
                    },
                    "state": {
                      "op": "if",
                      "when": {
                        "op": "equals",
                        "left": {
                          "op": "path",
                          "from": "candidate",
                          "path": "protocol"
                        },
                        "right": {
                          "op": "literal",
                          "value": "projected-consumer-runtime-v2"
                        }
                      },
                      "then": {
                        "op": "literal",
                        "value": "PROMOTED"
                      },
                      "else": {
                        "op": "if",
                        "when": {
                          "op": "equals",
                          "left": {
                            "op": "path",
                            "from": "candidate",
                            "path": "featureExists"
                          },
                          "right": {
                            "op": "literal",
                            "value": false
                          }
                        },
                        "then": {
                          "op": "literal",
                          "value": "FEATURE_REQUIRED"
                        },
                        "else": {
                          "op": "if",
                          "when": {
                            "op": "equals",
                            "left": {
                              "op": "path",
                              "from": "candidate",
                              "path": "workspaceExists"
                            },
                            "right": {
                              "op": "literal",
                              "value": false
                            }
                          },
                          "then": {
                            "op": "literal",
                            "value": "WORKSPACE_REQUIRED"
                          },
                          "else": {
                            "op": "literal",
                            "value": "CANDIDATE_READY"
                          }
                        }
                      }
                    }
                  }
                }
              }
            },
            "value": {
              "op": "object",
              "fields": {
                "decisionType": {
                  "op": "literal",
                  "value": "CLASSIFY_INVENTORY"
                },
                "inventory": {
                  "op": "object",
                  "fields": {
                    "inventoryType": {
                      "op": "literal",
                      "value": "tooling-projection-migration-inventory.v1"
                    },
                    "entries": {
                      "op": "path",
                      "from": "classifiedEntries",
                      "path": ""
                    },
                    "summary": {
                      "op": "object",
                      "fields": {
                        "FEATURE_REQUIRED": {
                          "op": "length",
                          "value": {
                            "op": "filter",
                            "from": {
                              "op": "path",
                              "from": "classifiedEntries",
                              "path": ""
                            },
                            "as": "entry",
                            "where": {
                              "op": "equals",
                              "left": {
                                "op": "path",
                                "from": "entry",
                                "path": "state"
                              },
                              "right": {
                                "op": "literal",
                                "value": "FEATURE_REQUIRED"
                              }
                            }
                          }
                        },
                        "WORKSPACE_REQUIRED": {
                          "op": "length",
                          "value": {
                            "op": "filter",
                            "from": {
                              "op": "path",
                              "from": "classifiedEntries",
                              "path": ""
                            },
                            "as": "entry",
                            "where": {
                              "op": "equals",
                              "left": {
                                "op": "path",
                                "from": "entry",
                                "path": "state"
                              },
                              "right": {
                                "op": "literal",
                                "value": "WORKSPACE_REQUIRED"
                              }
                            }
                          }
                        },
                        "CANDIDATE_READY": {
                          "op": "length",
                          "value": {
                            "op": "filter",
                            "from": {
                              "op": "path",
                              "from": "classifiedEntries",
                              "path": ""
                            },
                            "as": "entry",
                            "where": {
                              "op": "equals",
                              "left": {
                                "op": "path",
                                "from": "entry",
                                "path": "state"
                              },
                              "right": {
                                "op": "literal",
                                "value": "CANDIDATE_READY"
                              }
                            }
                          }
                        },
                        "PROMOTED": {
                          "op": "length",
                          "value": {
                            "op": "filter",
                            "from": {
                              "op": "path",
                              "from": "classifiedEntries",
                              "path": ""
                            },
                            "as": "entry",
                            "where": {
                              "op": "equals",
                              "left": {
                                "op": "path",
                                "from": "entry",
                                "path": "state"
                              },
                              "right": {
                                "op": "literal",
                                "value": "PROMOTED"
                              }
                            }
                          }
                        }
                      }
                    }
                  }
                }
              }
            }
          },
          "else": {
            "op": "if",
            "when": {
              "op": "equals",
              "left": {
                "op": "path",
                "from": "input",
                "path": "decisionType"
              },
              "right": {
                "op": "literal",
                "value": "PLAN_BINDING_REPLACEMENT"
              }
            },
            "then": {
              "op": "object",
              "fields": {
                "decisionType": {
                  "op": "literal",
                  "value": "PLAN_BINDING_REPLACEMENT"
                },
                "replacementDocument": {
                  "op": "object",
                  "fields": {
                    "bindingType": {
                      "op": "path",
                      "from": "input",
                      "path": "bindingDocument.bindingType"
                    },
                    "bindings": {
                      "op": "map",
                      "from": {
                        "op": "path",
                        "from": "input",
                        "path": "bindingDocument.bindings"
                      },
                      "as": "binding",
                      "value": {
                        "op": "if",
                        "when": {
                          "op": "equals",
                          "left": {
                            "op": "path",
                            "from": "binding",
                            "path": "responsibilityId"
                          },
                          "right": {
                            "op": "path",
                            "from": "input",
                            "path": "capability.responsibilityId"
                          }
                        },
                        "then": {
                          "op": "merge",
                          "values": [
                            {
                              "op": "path",
                              "from": "binding",
                              "path": ""
                            },
                            {
                              "op": "object",
                              "fields": {
                                "providerId": {
                                  "op": "path",
                                  "from": "input",
                                  "path": "capability.replacement.providerId"
                                },
                                "implementationRef": {
                                  "op": "path",
                                  "from": "input",
                                  "path": "capability.replacement.implementationRef"
                                },
                                "protocol": {
                                  "op": "path",
                                  "from": "input",
                                  "path": "capability.replacement.protocol"
                                }
                              }
                            }
                          ]
                        },
                        "else": {
                          "op": "path",
                          "from": "binding",
                          "path": ""
                        }
                      }
                    }
                  }
                }
              }
            },
            "else": {
              "op": "if",
              "when": {
                "op": "equals",
                "left": {
                  "op": "path",
                  "from": "input",
                  "path": "decisionType"
                },
                "right": {
                  "op": "literal",
                  "value": "EVALUATE_GATE"
                }
              },
              "then": {
                "op": "if",
                "when": {
                  "op": "equals",
                  "left": {
                    "op": "path",
                    "from": "input",
                    "path": "gateExitCode"
                  },
                  "right": {
                    "op": "literal",
                    "value": 0
                  }
                },
                "then": {
                  "op": "object",
                  "fields": {
                    "decisionType": {
                      "op": "literal",
                      "value": "EVALUATE_GATE"
                    },
                    "promotionDisposition": {
                      "op": "literal",
                      "value": "PROMOTED"
                    },
                    "bindingAction": {
                      "op": "literal",
                      "value": "KEEP_REPLACEMENT"
                    }
                  }
                },
                "else": {
                  "op": "object",
                  "fields": {
                    "decisionType": {
                      "op": "literal",
                      "value": "EVALUATE_GATE"
                    },
                    "promotionDisposition": {
                      "op": "literal",
                      "value": "ROLLED_BACK"
                    },
                    "bindingAction": {
                      "op": "literal",
                      "value": "RESTORE_ORIGINAL"
                    }
                  }
                }
              },
              "else": {
                "op": "if",
                "when": {
                  "op": "equals",
                  "left": {
                    "op": "path",
                    "from": "input",
                    "path": "decisionType"
                  },
                  "right": {
                    "op": "literal",
                    "value": "DETERMINE_EVIDENCE_DISPOSITION"
                  }
                },
                "then": {
                  "op": "object",
                  "fields": {
                    "decisionType": {
                      "op": "literal",
                      "value": "DETERMINE_EVIDENCE_DISPOSITION"
                    },
                    "evidenceDisposition": {
                      "op": "if",
                      "when": {
                        "op": "equals",
                        "left": {
                          "op": "path",
                          "from": "input",
                          "path": "verificationPassed"
                        },
                        "right": {
                          "op": "literal",
                          "value": false
                        }
                      },
                      "then": {
                        "op": "literal",
                        "value": "REJECTED"
                      },
                      "else": {
                        "op": "if",
                        "when": {
                          "op": "equals",
                          "left": {
                            "op": "path",
                            "from": "input",
                            "path": "promote"
                          },
                          "right": {
                            "op": "literal",
                            "value": false
                          }
                        },
                        "then": {
                          "op": "literal",
                          "value": "VERIFIED"
                        },
                        "else": {
                          "op": "if",
                          "when": {
                            "op": "equals",
                            "left": {
                              "op": "path",
                              "from": "input",
                              "path": "gateExitCode"
                            },
                            "right": {
                              "op": "literal",
                              "value": 0
                            }
                          },
                          "then": {
                            "op": "literal",
                            "value": "PROMOTED"
                          },
                          "else": {
                            "op": "literal",
                            "value": "REJECTED"
                          }
                        }
                      }
                    }
                  }
                },
                "else": {
                  "op": "object",
                  "fields": {
                    "decisionType": {
                      "op": "literal",
                      "value": "FINALIZE_RUN"
                    },
                    "runDisposition": {
                      "op": "if",
                      "when": {
                        "op": "some",
                        "from": {
                          "op": "path",
                          "from": "input",
                          "path": "runResults"
                        },
                        "as": "result",
                        "where": {
                          "op": "equals",
                          "left": {
                            "op": "path",
                            "from": "result",
                            "path": "disposition"
                          },
                          "right": {
                            "op": "literal",
                            "value": "REJECTED"
                          }
                        }
                      },
                      "then": {
                        "op": "literal",
                        "value": "COMPLETED_WITH_REJECTIONS"
                      },
                      "else": {
                        "op": "literal",
                        "value": "COMPLETED"
                      }
                    },
                    "continueIndependentCandidates": {
                      "op": "literal",
                      "value": true
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  ],
  "conformance": {
    "queryId": "scenario-conformance-closure",
    "platformMechanics": {
      "resolutionType": "consumer-platform-mechanic-resolution.v1",
      "projectionTarget": "node",
      "requirements": [
        {
          "mechanicId": "contract-document-reading",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "canonicalization",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "schema-admission",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "authority-resolution",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "semantic-execution",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "telemetry-observation",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "scenario-invocation",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "transition-binding-projection",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "interface-delivery",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "runtime-projection",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "artifact-result-delivery",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "authority-driven-transformation",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "durable-artifact-materialization",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1"
        },
        {
          "mechanicId": "contract-validation",
          "capabilityKind": "contract-validator",
          "requiredBy": "scenario-contract-admission",
          "requestedCapabilityId": "sda-schema-contract-admission.v1"
        },
        {
          "mechanicId": "cli-delivery",
          "capabilityKind": "interface-delivery",
          "requiredBy": "interface:tooling-migration-decision-cli",
          "requestedCapabilityId": "sda-json-cli.v1"
        },
        {
          "mechanicId": "json-reading",
          "capabilityKind": "interface-delivery",
          "requiredBy": "interface:tooling-migration-decision-cli",
          "requestedCapabilityId": "sda-json-cli.v1"
        },
        {
          "mechanicId": "json-serialization",
          "capabilityKind": "interface-delivery",
          "requiredBy": "interface:tooling-migration-decision-cli",
          "requestedCapabilityId": "sda-json-cli.v1"
        },
        {
          "mechanicId": "event-port-invocation",
          "capabilityKind": "event-port",
          "requiredBy": "port:decide-tooling-migration",
          "requestedCapabilityId": "sda-authority-transformation-port.v1"
        }
      ],
      "resolutions": [
        {
          "mechanicId": "contract-document-reading",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "canonicalization",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "schema-admission",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "authority-resolution",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "semantic-execution",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "telemetry-observation",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "scenario-invocation",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "transition-binding-projection",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "interface-delivery",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "runtime-projection",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "artifact-result-delivery",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "authority-driven-transformation",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "durable-artifact-materialization",
          "capabilityKind": "consumer-runtime",
          "requiredBy": "mandatory-profile:sda-consumer-mandatory-mechanics.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-node-consumer-runtime.v1",
          "provider": "ScenarioKernel.NodePlatform",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "contract-validation",
          "capabilityKind": "contract-validator",
          "requiredBy": "scenario-contract-admission",
          "requestedCapabilityId": "sda-schema-contract-admission.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-schema-contract-admission.v1",
          "provider": "ScenarioKernel.NodePlatform.Schema.JsonSchemaContractAdmission",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "cli-delivery",
          "capabilityKind": "interface-delivery",
          "requiredBy": "interface:tooling-migration-decision-cli",
          "requestedCapabilityId": "sda-json-cli.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-json-cli.v1",
          "provider": "ScenarioKernel.NodePlatform.Interface.JsonCli",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "json-reading",
          "capabilityKind": "interface-delivery",
          "requiredBy": "interface:tooling-migration-decision-cli",
          "requestedCapabilityId": "sda-json-cli.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-json-cli.v1",
          "provider": "ScenarioKernel.NodePlatform.Interface.JsonCli",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "json-serialization",
          "capabilityKind": "interface-delivery",
          "requiredBy": "interface:tooling-migration-decision-cli",
          "requestedCapabilityId": "sda-json-cli.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-json-cli.v1",
          "provider": "ScenarioKernel.NodePlatform.Interface.JsonCli",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        },
        {
          "mechanicId": "event-port-invocation",
          "capabilityKind": "event-port",
          "requiredBy": "port:decide-tooling-migration",
          "requestedCapabilityId": "sda-authority-transformation-port.v1",
          "status": "AVAILABLE",
          "capabilityId": "sda-authority-transformation-port.v1",
          "provider": "ScenarioKernel.NodePlatform.Execution.AuthorityTransformation",
          "implementationRef": "languages/typescript/runtimes/node/admitted-consumer-platform.mjs",
          "conformanceRef": "tools/tests/consumer-projection/platform-capability-admission.test.js"
        }
      ],
      "disposition": "RESOLVED"
    },
    "executableOrigin": {
      "originType": "consumer-executable-origin.v1",
      "disposition": "PROJECTED_ONLY",
      "unauthorizedFiles": []
    },
    "closures": [
      {
        "closureId": "feature-to-scenario",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "scenario-to-contract",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "scenario-to-event-authority",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "outcome-to-transition",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "transition-to-next-input",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "scenario-to-interface",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "execution-to-telemetry",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "scenario-to-projection",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "expected-to-observed-execution",
        "evaluation": "runtime-evidence",
        "evaluatorId": "expected-execution-trace.v1",
        "configuration": {
          "expectedTelemetry": {
            "traceType": "projected-expected-consumer-trace.v1",
            "telemetryId": "consumer-scenario-execution-telemetry",
            "capabilityId": "decide-tooling-migration",
            "rootScenarioId": "decide-tooling-migration",
            "observationType": "scenario-execution-observation.v1",
            "lineageFields": [
              "executionId",
              "rootExecutionId",
              "parentExecutionId",
              "scenarioId"
            ],
            "scenarios": [
              {
                "scenarioId": "decide-tooling-migration",
                "steps": [
                  "admit-input",
                  "resolve-event-authority",
                  "execute-event-authority",
                  "admit-outcome",
                  "resolve-disposition"
                ],
                "expectedTransitionId": null
              }
            ]
          }
        }
      },
      {
        "closureId": "root-to-terminal-behavior",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "required-mechanic-to-platform-capability",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "consumer-executable-origin",
        "evaluation": "runtime-evidence",
        "evaluatorId": "projected-origin-observation.v1",
        "configuration": {
          "requiredDisposition": "PURE_PROJECTION_CONFORMS"
        }
      },
      {
        "closureId": "dynamic-semantic-execution",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      },
      {
        "closureId": "domain-contract-admission",
        "evaluation": "compiled",
        "disposition": "PASS",
        "findings": []
      }
    ]
  },
  "requiredProviderCapabilityIds": [
    "sda-authority-transformation-port.v1",
    "sda-schema-contract-admission.v1"
  ]
}
';
DECLARE @tooling_decision_fixtures_document nvarchar(max)=N'{
  "fixtureType": "consumer-capability-fixtures.v1",
  "fixtures": [
    {
      "fixtureId": "inventory-classifies-every-migration-state",
      "input": {
        "decisionType": "CLASSIFY_INVENTORY",
        "candidates": [
          {
            "capabilityId": "feature",
            "groupId": "group",
            "responsibilityId": "feature-responsibility",
            "providerId": "legacy-feature",
            "protocol": "responsibility-provider-v1",
            "featureRef": "feature.feature",
            "workspaceRef": "feature",
            "featureExists": false,
            "workspaceExists": false
          },
          {
            "capabilityId": "workspace",
            "groupId": "group",
            "responsibilityId": "workspace-responsibility",
            "providerId": "legacy-workspace",
            "protocol": "responsibility-provider-v1",
            "featureRef": "workspace.feature",
            "workspaceRef": "workspace",
            "featureExists": true,
            "workspaceExists": false
          },
          {
            "capabilityId": "candidate",
            "groupId": "group",
            "responsibilityId": "candidate-responsibility",
            "providerId": "legacy-candidate",
            "protocol": "responsibility-provider-v1",
            "featureRef": "candidate.feature",
            "workspaceRef": "candidate",
            "featureExists": true,
            "workspaceExists": true
          },
          {
            "capabilityId": "promoted",
            "groupId": "group",
            "responsibilityId": "promoted-responsibility",
            "providerId": "projected-provider",
            "protocol": "projected-consumer-runtime-v2",
            "featureRef": "promoted.feature",
            "workspaceRef": "promoted",
            "featureExists": true,
            "workspaceExists": true
          }
        ],
        "bindingDocument": {
          "bindingType": "responsibility-provider-bindings.v1",
          "bindings": []
        },
        "capability": {
          "responsibilityId": "unused",
          "replacement": {
            "providerId": "unused-provider",
            "implementationRef": "unused.mjs",
            "protocol": "projected-consumer-runtime-v2"
          }
        },
        "gateExitCode": 0,
        "promote": false,
        "verificationPassed": true,
        "runResults": []
      },
      "portOutcomes": {
        "authority-driven-composition": {
          "authority": "interfaces.authority.json"
        }
      },
      "expected": {
        "disposition": "terminated",
        "terminalScenarioId": "decide-tooling-migration",
        "scenarioSequence": [
          "decide-tooling-migration"
        ],
        "outcomeAssertions": [
          {
            "conditionId": "feature-state",
            "path": "inventory.entries.0.state",
            "operator": "equals",
            "value": "FEATURE_REQUIRED"
          },
          {
            "conditionId": "workspace-state",
            "path": "inventory.entries.1.state",
            "operator": "equals",
            "value": "WORKSPACE_REQUIRED"
          },
          {
            "conditionId": "candidate-state",
            "path": "inventory.entries.2.state",
            "operator": "equals",
            "value": "CANDIDATE_READY"
          },
          {
            "conditionId": "promoted-state",
            "path": "inventory.entries.3.state",
            "operator": "equals",
            "value": "PROMOTED"
          },
          {
            "conditionId": "all-states-counted",
            "path": "inventory.summary.PROMOTED",
            "operator": "equals",
            "value": 1
          }
        ]
      }
    },
    {
      "fixtureId": "replacement-changes-only-selected-binding",
      "input": {
        "decisionType": "PLAN_BINDING_REPLACEMENT",
        "candidates": [],
        "bindingDocument": {
          "bindingType": "responsibility-provider-bindings.v1",
          "bindings": [
            {
              "responsibilityId": "selected",
              "providerId": "legacy-selected",
              "implementationRef": "legacy/selected.mjs",
              "requires": [
                "filesystem"
              ]
            },
            {
              "responsibilityId": "other",
              "providerId": "other-provider",
              "implementationRef": "other.mjs",
              "requires": []
            }
          ]
        },
        "capability": {
          "responsibilityId": "selected",
          "replacement": {
            "providerId": "projected-selected",
            "implementationRef": "projected/selected.mjs",
            "protocol": "projected-consumer-runtime-v2"
          }
        },
        "gateExitCode": 0,
        "promote": true,
        "verificationPassed": true,
        "runResults": []
      },
      "portOutcomes": {
        "authority-driven-composition": {
          "authority": "interfaces.authority.json"
        }
      },
      "expected": {
        "disposition": "terminated",
        "terminalScenarioId": "decide-tooling-migration",
        "scenarioSequence": [
          "decide-tooling-migration"
        ],
        "outcomeAssertions": [
          {
            "conditionId": "selected-provider-replaced",
            "path": "replacementDocument.bindings.0.providerId",
            "operator": "equals",
            "value": "projected-selected"
          },
          {
            "conditionId": "selected-requirements-preserved",
            "path": "replacementDocument.bindings.0.requires.0",
            "operator": "equals",
            "value": "filesystem"
          },
          {
            "conditionId": "other-provider-preserved",
            "path": "replacementDocument.bindings.1.providerId",
            "operator": "equals",
            "value": "other-provider"
          }
        ]
      }
    },
    {
      "fixtureId": "passing-gate-keeps-projected-binding",
      "input": {
        "decisionType": "EVALUATE_GATE",
        "candidates": [],
        "bindingDocument": {
          "bindingType": "responsibility-provider-bindings.v1",
          "bindings": []
        },
        "capability": {
          "responsibilityId": "unused",
          "replacement": {
            "providerId": "unused-provider",
            "implementationRef": "unused.mjs",
            "protocol": "projected-consumer-runtime-v2"
          }
        },
        "gateExitCode": 0,
        "promote": true,
        "verificationPassed": true,
        "runResults": []
      },
      "portOutcomes": {
        "authority-driven-composition": {
          "authority": "interfaces.authority.json"
        }
      },
      "expected": {
        "disposition": "terminated",
        "terminalScenarioId": "decide-tooling-migration",
        "scenarioSequence": [
          "decide-tooling-migration"
        ],
        "outcomeAssertions": [
          {
            "conditionId": "promotion-admitted",
            "path": "promotionDisposition",
            "operator": "equals",
            "value": "PROMOTED"
          },
          {
            "conditionId": "replacement-kept",
            "path": "bindingAction",
            "operator": "equals",
            "value": "KEEP_REPLACEMENT"
          }
        ]
      }
    },
    {
      "fixtureId": "failing-gate-restores-original-binding",
      "input": {
        "decisionType": "EVALUATE_GATE",
        "candidates": [],
        "bindingDocument": {
          "bindingType": "responsibility-provider-bindings.v1",
          "bindings": []
        },
        "capability": {
          "responsibilityId": "unused",
          "replacement": {
            "providerId": "unused-provider",
            "implementationRef": "unused.mjs",
            "protocol": "projected-consumer-runtime-v2"
          }
        },
        "gateExitCode": 1,
        "promote": true,
        "verificationPassed": true,
        "runResults": []
      },
      "portOutcomes": {
        "authority-driven-composition": {
          "authority": "interfaces.authority.json"
        }
      },
      "expected": {
        "disposition": "terminated",
        "terminalScenarioId": "decide-tooling-migration",
        "scenarioSequence": [
          "decide-tooling-migration"
        ],
        "outcomeAssertions": [
          {
            "conditionId": "promotion-rejected",
            "path": "promotionDisposition",
            "operator": "equals",
            "value": "ROLLED_BACK"
          },
          {
            "conditionId": "original-restored",
            "path": "bindingAction",
            "operator": "equals",
            "value": "RESTORE_ORIGINAL"
          }
        ]
      }
    },
    {
      "fixtureId": "verified-candidate-publishes-verified-evidence",
      "input": {
        "decisionType": "DETERMINE_EVIDENCE_DISPOSITION",
        "candidates": [],
        "bindingDocument": {
          "bindingType": "responsibility-provider-bindings.v1",
          "bindings": []
        },
        "capability": {
          "responsibilityId": "unused",
          "replacement": {
            "providerId": "unused-provider",
            "implementationRef": "unused.mjs",
            "protocol": "projected-consumer-runtime-v2"
          }
        },
        "gateExitCode": 0,
        "promote": false,
        "verificationPassed": true,
        "runResults": []
      },
      "portOutcomes": {
        "authority-driven-composition": {
          "authority": "interfaces.authority.json"
        }
      },
      "expected": {
        "disposition": "terminated",
        "terminalScenarioId": "decide-tooling-migration",
        "scenarioSequence": [
          "decide-tooling-migration"
        ],
        "outcomeAssertions": [
          {
            "conditionId": "verification-visible",
            "path": "evidenceDisposition",
            "operator": "equals",
            "value": "VERIFIED"
          }
        ]
      }
    },
    {
      "fixtureId": "failed-verification-publishes-rejected-evidence",
      "input": {
        "decisionType": "DETERMINE_EVIDENCE_DISPOSITION",
        "candidates": [],
        "bindingDocument": {
          "bindingType": "responsibility-provider-bindings.v1",
          "bindings": []
        },
        "capability": {
          "responsibilityId": "unused",
          "replacement": {
            "providerId": "unused-provider",
            "implementationRef": "unused.mjs",
            "protocol": "projected-consumer-runtime-v2"
          }
        },
        "gateExitCode": 0,
        "promote": true,
        "verificationPassed": false,
        "runResults": []
      },
      "portOutcomes": {
        "authority-driven-composition": {
          "authority": "interfaces.authority.json"
        }
      },
      "expected": {
        "disposition": "terminated",
        "terminalScenarioId": "decide-tooling-migration",
        "scenarioSequence": [
          "decide-tooling-migration"
        ],
        "outcomeAssertions": [
          {
            "conditionId": "rejection-visible",
            "path": "evidenceDisposition",
            "operator": "equals",
            "value": "REJECTED"
          }
        ]
      }
    },
    {
      "fixtureId": "run-continues-independent-candidates-after-rejection",
      "input": {
        "decisionType": "FINALIZE_RUN",
        "candidates": [],
        "bindingDocument": {
          "bindingType": "responsibility-provider-bindings.v1",
          "bindings": []
        },
        "capability": {
          "responsibilityId": "unused",
          "replacement": {
            "providerId": "unused-provider",
            "implementationRef": "unused.mjs",
            "protocol": "projected-consumer-runtime-v2"
          }
        },
        "gateExitCode": 1,
        "promote": true,
        "verificationPassed": true,
        "runResults": [
          {
            "capabilityId": "alpha",
            "disposition": "REJECTED"
          },
          {
            "capabilityId": "beta",
            "disposition": "PROMOTED"
          }
        ]
      },
      "portOutcomes": {
        "authority-driven-composition": {
          "authority": "interfaces.authority.json"
        }
      },
      "expected": {
        "disposition": "terminated",
        "terminalScenarioId": "decide-tooling-migration",
        "scenarioSequence": [
          "decide-tooling-migration"
        ],
        "outcomeAssertions": [
          {
            "conditionId": "aggregate-rejection-visible",
            "path": "runDisposition",
            "operator": "equals",
            "value": "COMPLETED_WITH_REJECTIONS"
          },
          {
            "conditionId": "continuation-required",
            "path": "continueIndependentCandidates",
            "operator": "equals",
            "value": true
          }
        ]
      }
    }
  ]
}
';
DECLARE @tooling_decision_sterility_document nvarchar(max)=N'{
  "conformanceType": "projected-artifact-mechanical-sterility.v1",
  "sourceOrigin": "PROJECTED",
  "forbiddenExecutableMechanics": {
    "branch": 0,
    "iteration": 0,
    "exception-handling": 0,
    "throw": 0,
    "object-construction": 0,
    "serialization": 0,
    "normalization": 0,
    "validation": 0,
    "fallback": 0,
    "retry": 0,
    "state-mutation": 0,
    "meaning-hidden-in-text": 0
  },
  "violations": [],
  "disposition": "PURE_PROJECTION_CONFORMS"
}
';
DECLARE @tooling_decision_declared_application nvarchar(max)=N'{"bindingDocument":' + N'"' + STRING_ESCAPE(@tooling_decision_binding_document,'json') + N'"' + N',"executionPlanDocument":' + N'"' + STRING_ESCAPE(@tooling_decision_plan_document,'json') + N'"' + N',"fixturesDocument":' + N'"' + STRING_ESCAPE(@tooling_decision_fixtures_document,'json') + N'"' + N',"mechanicalSterilityDocument":' + N'"' + STRING_ESCAPE(@tooling_decision_sterility_document,'json') + N'"' + N'}';

-- =====================================================================
-- Replace the SDA capability-tree bindingRef with the declared application.
-- =====================================================================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
DECLARE @targets TABLE (
  namespace_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  declared_id nvarchar(400) COLLATE Latin1_General_100_BIN2,
  declared_application nvarchar(max),
  semantics nvarchar(max),
  prevver bigint,
  changed bit DEFAULT 0,
  PRIMARY KEY (namespace_id, declared_id));
INSERT @targets (namespace_id, declared_id, declared_application) VALUES
 (N'sidefx:capability:obtain-governed-model-response', N'bind-gemini-os-credential-port', @os_credential_declared_application),
 (N'sidefx:capability:obtain-governed-model-response', N'bind-openai-os-credential-port', @os_credential_declared_application),
 (N'sidefx:capability:operate-tooling-migration-inventory', N'classify-inventory-port', @tooling_decision_declared_application),
 (N'sidefx:capability:operate-tooling-migration-conveyor', N'resolve-disposition-port', @tooling_decision_declared_application);

UPDATE t SET semantics=JSON_QUERY(d.definition_json,'$.semantics'),
  prevver=(SELECT pv.port_version_pk FROM model.port_version pv WHERE pv.semantic_object_definition_pk=d.semantic_object_definition_pk)
FROM @targets t
JOIN analysis.v_selected_semantic_definition d
  ON d.estate_model_pk=@estate AND d.object_kind='PORT'
 AND d.namespace_id=t.namespace_id COLLATE Latin1_General_100_BIN2
 AND d.declared_id=t.declared_id COLLATE Latin1_General_100_BIN2;
IF (SELECT COUNT(*) FROM @targets WHERE semantics IS NULL)<>0 THROW 51000,'DECLARED_BINDING_PORT_NOT_FOUND',1;
IF EXISTS (SELECT 1 FROM @targets WHERE prevver IS NULL) THROW 51000,'DECLARED_BINDING_PORT_VERSION_MISSING',1;
IF EXISTS (SELECT 1 FROM @targets
  WHERE JSON_QUERY(semantics,'$.configuration.declaredApplication') IS NULL
    AND ISNULL(JSON_VALUE(semantics,'$.configuration.bindingRef'),N'') NOT LIKE N'%capabilities/%')
  THROW 51000,'DECLARED_BINDING_PORT_DIVERGED',1;

DECLARE @namespace nvarchar(400), @declared nvarchar(400), @semantics nvarchar(max), @application nvarchar(max),
  @prevver bigint, @object bigint, @definition bigint, @digest binary(32), @version bigint, @portpk bigint;
DECLARE port_cursor CURSOR LOCAL FAST_FORWARD FOR
  SELECT namespace_id, declared_id, semantics, declared_application, prevver
  FROM @targets WHERE JSON_QUERY(semantics,'$.configuration.declaredApplication') IS NULL
  ORDER BY namespace_id, declared_id;
OPEN port_cursor;
FETCH NEXT FROM port_cursor INTO @namespace, @declared, @semantics, @application, @prevver;
WHILE @@FETCH_STATUS=0 BEGIN
  SET @semantics=JSON_MODIFY(@semantics,'$.configuration.declaredApplication',JSON_QUERY(@application));
  SET @semantics=JSON_MODIFY(@semantics,'$.configuration.bindingRef',NULL);
  SET @semantics=JSON_MODIFY(@semantics,'$.configuration.bindingBase',NULL);
  EXEC model.put_semantic_definition 'PORT', @namespace, @declared, @semantics,
    @object OUTPUT, @definition OUTPUT, @digest OUTPUT;
  SET @portpk=(SELECT port_pk FROM model.port WHERE semantic_object_pk=@object);
  IF @portpk IS NULL THROW 51000,'DECLARED_BINDING_PORT_ROW_MISSING',1;
  SET @version=(SELECT port_version_pk FROM model.port_version WHERE semantic_object_definition_pk=@definition);
  IF @version IS NULL BEGIN
    INSERT model.port_version(port_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,
      port_profile,object_kind,_owner_definition_pk,_canonical_pointer)
    VALUES(@portpk,@object,@definition,@digest,'consumer-interface-authority.v1','PORT',@definition,N'');
    SET @version=SCOPE_IDENTITY();
  END
  UPDATE model.operation_port_invocation SET port_version_pk=@version WHERE port_version_pk=@prevver;
  UPDATE @targets SET changed=1 WHERE namespace_id=@namespace COLLATE Latin1_General_100_BIN2
    AND declared_id=@declared COLLATE Latin1_General_100_BIN2;
  FETCH NEXT FROM port_cursor INTO @namespace, @declared, @semantics, @application, @prevver;
END
CLOSE port_cursor;
DEALLOCATE port_cursor;
GO
-- =====================================================================
-- Verification.
-- =====================================================================
DECLARE @estate bigint=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1);
SELECT '1_declared_bindings' AS result_set, d.namespace_id, d.declared_id,
  d.semantic_object_definition_pk AS sod,
  CASE WHEN JSON_QUERY(d.definition_json,'$.semantics.configuration.declaredApplication') IS NULL THEN 0 ELSE 1 END AS declared_application,
  CASE WHEN JSON_VALUE(d.definition_json,'$.semantics.configuration.bindingRef') IS NULL THEN 0 ELSE 1 END AS binding_ref,
  JSON_VALUE(d.definition_json,'$.semantics.configuration.bindingDigest') AS binding_digest,
  JSON_VALUE(d.definition_json,'$.semantics.configuration.capabilityAuthorityDigest') AS authority_digest
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.declared_id IN (N'bind-gemini-os-credential-port',N'bind-openai-os-credential-port',N'classify-inventory-port',N'resolve-disposition-port')
ORDER BY d.declared_id;
SELECT '2_declared_documents' AS result_set, d.declared_id,
  LEN(d.definition_json) AS semantics_chars,
  LEN(JSON_VALUE(d.definition_json,'$.semantics.configuration.declaredApplication.bindingDocument')) AS binding_document_chars,
  JSON_VALUE(JSON_VALUE(d.definition_json,'$.semantics.configuration.declaredApplication.bindingDocument'),'$.executionPlanDigest') AS pinned_plan_digest
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND d.declared_id IN (N'bind-gemini-os-credential-port',N'bind-openai-os-credential-port',N'classify-inventory-port',N'resolve-disposition-port')
ORDER BY d.declared_id;
SELECT '3_remaining_sda_capabilities_binding_refs' AS result_set, COUNT(*) AS count
FROM analysis.v_selected_semantic_definition d
WHERE d.estate_model_pk=@estate AND d.object_kind='PORT'
  AND (JSON_VALUE(d.definition_json,'$.semantics.configuration.bindingRef') LIKE N'%scenario-driven-architecture/capabilities/%'
    OR JSON_VALUE(d.definition_json,'$.semantics.configuration.bindingBase') LIKE N'%capabilities/%');
GO
COMMIT TRANSACTION;
-- Installed: the four Port rows compose their projected applications from
-- configuration.declaredApplication; no bindingRef resolves into
-- scenario-driven-architecture/capabilities/**. Reversal: a migration that
-- restores the bindingRef/bindingBase configuration the four rows carried.
