-- Restore the declared blueprint schema and include its referenced schema rows.
-- Keep the existing unavailable outcome and decode only a completed response.
SET NOCOUNT ON;
SET XACT_ABORT ON;
BEGIN TRANSACTION;
DECLARE @trigger_name nvarchar(517), @triggers CURSOR;
SET @triggers=CURSOR LOCAL FAST_FORWARD FOR
 SELECT QUOTENAME(s.name)+N'.'+QUOTENAME(t.name)
 FROM sys.triggers t JOIN sys.objects o ON o.object_id=t.parent_id
 JOIN sys.schemas s ON s.schema_id=o.schema_id
 WHERE o.type='U' AND s.name IN ('model','source')
 AND (t.name LIKE 'guard%' OR t.name LIKE '%immutable%');
OPEN @triggers;
FETCH NEXT FROM @triggers INTO @trigger_name;
WHILE @@FETCH_STATUS=0 BEGIN
 EXEC(N'DROP TRIGGER '+@trigger_name);
 FETCH NEXT FROM @triggers INTO @trigger_name;
END;
CLOSE @triggers;
DEALLOCATE @triggers;
IF OBJECT_ID('analysis.fn_contract_schema_closure') IS NOT NULL THROW 51000,'CONTRACT_SCHEMA_CLOSURE_ALREADY_DECLARED',1;
GO
CREATE OR ALTER PROCEDURE model.declare_contract
 @id nvarchar(400),@schema nvarchar(max)
WITH EXECUTE AS OWNER
AS
BEGIN
 SET NOCOUNT ON;
 IF ISJSON(@schema)<>1 THROW 51000,'CONTRACT_SCHEMA_INVALID',1;
 DECLARE @bytes varbinary(max)=CONVERT(varbinary(max),CONVERT(varchar(max),@schema COLLATE Latin1_General_100_BIN2_UTF8));
 DECLARE @schema_digest binary(32)=HASHBYTES('SHA2_256',@bytes),@object bigint,@definition bigint,@digest binary(32);
 IF NOT EXISTS (SELECT 1 FROM source.content_object WHERE content_digest=@schema_digest)
  INSERT source.content_object(content_digest,content_bytes,byte_length) VALUES(@schema_digest,@bytes,DATALENGTH(@bytes));
 DECLARE @schema_pk bigint=(SELECT schema_object_pk FROM model.schema_object WHERE content_digest=@schema_digest);
 IF @schema_pk IS NULL BEGIN
  INSERT model.schema_object(content_digest,dialect,content_object_pk)
   VALUES(@schema_digest,JSON_VALUE(@schema,'$."$schema"'),(SELECT content_object_pk FROM source.content_object WHERE content_digest=@schema_digest));
  SET @schema_pk=SCOPE_IDENTITY();
 END;
 DECLARE @semantics nvarchar(max)=(SELECT LOWER(CONVERT(varchar(64),@schema_digest,2)) AS schema_digest,
  JSON_VALUE(@schema,'$."$id"') AS schema_id FOR JSON PATH,WITHOUT_ARRAY_WRAPPER);
 EXEC model.put_semantic_definition 'CONTRACT',N'sidefx:contracts',@id,@semantics,@object OUTPUT,@definition OUTPUT,@digest OUTPUT;
 DECLARE @contract bigint=(SELECT contract_pk FROM model.contract WHERE semantic_object_pk=@object);
 IF @contract IS NULL BEGIN
  INSERT model.contract(namespace_pk,contract_id,semantic_object_pk,object_kind)
   SELECT namespace_pk,@id,@object,'CONTRACT' FROM model.semantic_object WHERE semantic_object_pk=@object;
  SET @contract=SCOPE_IDENTITY();
 END;
 IF NOT EXISTS (SELECT 1 FROM model.contract_version WHERE semantic_object_definition_pk=@definition)
  INSERT model.contract_version(contract_pk,semantic_object_pk,semantic_object_definition_pk,definition_digest,schema_object_pk,object_kind,_owner_definition_pk,_canonical_pointer,schema_reference_state)
   VALUES(@contract,@object,@definition,@digest,@schema_pk,'CONTRACT',@definition,N'','RESOLVED');
END;
GO
EXEC model.declare_contract @id=N'canonical-circuit-blueprint.v1',@schema=N'{
  "$schema": "https://json-schema.org/draft/2020-12/schema",
  "$id": "https://agentic-harness.local/contracts/canonical-circuit-blueprint.v1.schema.json",
  "title": "canonical-circuit-blueprint.v1",
  "description": "Normalized carrier for one capability''s canonical circuit blueprint. Structural authority only: it constrains shape, closed vocabularies, and locally decidable field applicability. Graph-wide obligations - acyclicity outside declared bounded returns, complete branch variant coverage, jointly required fan-out membership, complete convergence requirement sets, monotonic advancement, and observability sufficiency - are owned by inspect-canonical-circuit-blueprint-candidate and prove-canonical-blueprint-geometry, not by this schema.",
  "type": "object",
  "additionalProperties": false,
  "required": [
    "carrierVersion",
    "capability",
    "sourceAuthority",
    "blueprintAuthority",
    "nodes",
    "edges",
    "projectionAuthorities"
  ],
  "properties": {
    "$schema": { "type": "string" },

    "carrierVersion": { "const": "canonical-circuit-blueprint.v1" },

    "capability": {
      "type": "object",
      "additionalProperties": false,
      "required": ["capabilityId", "version", "rootExperience"],
      "properties": {
        "capabilityId": { "$ref": "#/$defs/semanticIdentity" },
        "version": { "type": "string", "minLength": 1 },
        "rootExperience": { "type": "string", "minLength": 1 },
        "capabilityAuthorityDigest": { "$ref": "#/$defs/digest" },
        "capsuleDigest": { "$ref": "#/$defs/digest" }
      }
    },

    "sourceAuthority": {
      "type": "object",
      "additionalProperties": false,
      "required": ["disposition", "lineage"],
      "properties": {
        "disposition": {
          "enum": ["CANDIDATE", "ADMITTED"],
          "description": "Projection never upgrades a CANDIDATE carrier to ADMITTED."
        },
        "featureAuthorityRef": { "$ref": "#/$defs/authorityRef" },
        "lineage": {
          "type": "array",
          "minItems": 1,
          "items": { "$ref": "#/$defs/authorityRef" }
        }
      }
    },

    "blueprintAuthority": {
      "type": "object",
      "additionalProperties": false,
      "required": ["blueprintId", "authorityDigest"],
      "properties": {
        "blueprintId": { "$ref": "#/$defs/semanticIdentity" },
        "authorityDigest": { "$ref": "#/$defs/digest" }
      }
    },

    "nodes": {
      "type": "array",
      "minItems": 1,
      "items": { "$ref": "#/$defs/node" }
    },

    "edges": {
      "type": "array",
      "items": { "$ref": "#/$defs/edge" }
    },

    "structuralMapping": {
      "$comment": "Governed C4 mappings to structural realization authority.",
      "type": "object",
      "additionalProperties": false,
      "required": ["context", "container", "component"],
      "properties": {
        "context": { "$ref": "#/$defs/c4Mapping" },
        "container": { "$ref": "#/$defs/c4Mapping" },
        "component": { "$ref": "#/$defs/c4Mapping" },
        "code": {
          "$comment": "Optional and always projected; never authored as structural authority.",
          "$ref": "#/$defs/c4Mapping"
        }
      }
    },

    "serviceLevel": {
      "type": "object",
      "additionalProperties": false,
      "required": ["indicators", "objectives"],
      "properties": {
        "indicators": {
          "type": "array",
          "items": { "$ref": "#/$defs/sliDefinition" }
        },
        "objectives": {
          "type": "array",
          "items": { "$ref": "#/$defs/sloDefinition" }
        },
        "agreements": {
          "type": "array",
          "items": { "$ref": "#/$defs/slaBoundary" }
        },
        "crossApplyParity": {
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": ["targetId", "preservedIdentities"],
            "properties": {
              "targetId": { "$ref": "#/$defs/semanticIdentity" },
              "preservedIdentities": {
                "type": "array",
                "minItems": 1,
                "items": { "$ref": "#/$defs/semanticIdentity" }
              },
              "correlationRuleRef": { "$ref": "#/$defs/authorityRef" }
            }
          }
        }
      }
    },

    "projectionAuthorities": {
      "$comment": "Profiles and views this blueprint permits. A projector may not emit a profile absent from this list.",
      "type": "object",
      "additionalProperties": false,
      "required": ["profiles", "views"],
      "properties": {
        "profiles": {
          "type": "array",
          "minItems": 1,
          "items": { "$ref": "#/$defs/authorityRef" }
        },
        "views": {
          "type": "array",
          "minItems": 1,
          "items": {
            "enum": [
              "SCENARIO",
              "MONOTONIC",
              "BRANCH",
              "DEPENDENCY",
              "ALTITUDE",
              "PROVIDER",
              "EVIDENCE",
              "RUNTIME_PLAY",
              "SEMANTIC_DIFF",
              "C4",
              "OBSERVABILITY",
              "SERVICE_LEVEL"
            ]
          }
        }
      }
    }
  },

  "$defs": {
    "semanticIdentity": {
      "type": "string",
      "minLength": 1,
      "pattern": "^[a-z0-9]+(-[a-z0-9]+)*(\\.v[0-9]+)?$",
      "description": "Stable kebab-case semantic identity, optionally version-suffixed. Never a filesystem path or generated symbol."
    },

    "digest": {
      "type": "string",
      "pattern": "^sha256:[0-9a-f]{64}$"
    },

    "authorityRef": {
      "type": "object",
      "additionalProperties": false,
      "required": ["authorityId", "digest"],
      "properties": {
        "authorityId": { "$ref": "#/$defs/semanticIdentity" },
        "digest": { "$ref": "#/$defs/digest" }
      }
    },

    "projectionOrdinal": {
      "type": "integer",
      "minimum": 0,
      "description": "Deterministic display order for otherwise independent peers. Presentation authority only; carries no execution or precedence meaning."
    },

    "altitude": {
      "enum": ["CAPABILITY", "OPERATION", "MECHANIC", "PROVIDER"],
      "description": "CAPABILITY uses the scenario cell (Input/Event/Outcome). Lower altitudes retain the three-position protocol with their own semantic nouns and never acquire the promised experience."
    },

    "cell": {
      "$comment": "The three-position protocol. Position nouns differ by altitude; the geometry does not.",
      "type": "object",
      "additionalProperties": false,
      "required": ["first", "energized", "result"],
      "properties": {
        "first": {
          "type": "object",
          "additionalProperties": false,
          "required": ["identity", "contract"],
          "properties": {
            "identity": { "$ref": "#/$defs/semanticIdentity" },
            "contract": { "$ref": "#/$defs/authorityRef" }
          }
        },
        "energized": {
          "type": "object",
          "additionalProperties": false,
          "required": ["identity", "authority"],
          "properties": {
            "identity": { "$ref": "#/$defs/semanticIdentity" },
            "authority": { "$ref": "#/$defs/authorityRef" }
          }
        },
        "result": {
          "type": "object",
          "additionalProperties": false,
          "required": ["identity", "contract"],
          "properties": {
            "identity": { "$ref": "#/$defs/semanticIdentity" },
            "contract": { "$ref": "#/$defs/authorityRef" },
            "variants": {
              "$comment": "Declared Outcome variants. Decisionality is owned here, never by an inserted decision node.",
              "type": "array",
              "items": {
                "type": "object",
                "additionalProperties": false,
                "required": ["variantId", "projectionOrdinal"],
                "properties": {
                  "variantId": {
                    "type": "string",
                    "pattern": "^[A-Z][A-Z0-9_]*$"
                  },
                  "projectionOrdinal": { "$ref": "#/$defs/projectionOrdinal" }
                }
              }
            }
          }
        }
      }
    },

    "node": {
      "type": "object",
      "additionalProperties": false,
      "required": ["nodeId", "kind", "altitude", "projectionOrdinal"],
      "properties": {
        "nodeId": { "$ref": "#/$defs/semanticIdentity" },
        "kind": {
          "enum": [
            "state",
            "responsibility",
            "outcome",
            "junction",
            "convergence",
            "provider-slot",
            "terminal"
          ]
        },
        "altitude": { "$ref": "#/$defs/altitude" },
        "projectionOrdinal": { "$ref": "#/$defs/projectionOrdinal" },
        "cell": { "$ref": "#/$defs/cell" },
        "requiredProducts": {
          "$comment": "Complete set of upstream products a convergence node''s Input contract demands. Jointly required, never alternatives.",
          "type": "array",
          "minItems": 2,
          "items": { "$ref": "#/$defs/semanticIdentity" }
        },
        "terminalDisposition": { "type": "string", "minLength": 1 },
        "providerSlot": {
          "type": "object",
          "additionalProperties": false,
          "required": ["portId", "mode"],
          "properties": {
            "portId": { "$ref": "#/$defs/semanticIdentity" },
            "mode": { "$ref": "#/$defs/semanticIdentity" }
          }
        },
        "observability": { "$ref": "#/$defs/observabilityContract" }
      },
      "allOf": [
        {
          "$comment": "A junction is an Outcome that declares more than one variant.",
          "if": { "properties": { "kind": { "const": "junction" } }, "required": ["kind"] },
          "then": {
            "required": ["cell"],
            "properties": {
              "cell": {
                "properties": {
                  "result": {
                    "required": ["variants"],
                    "properties": { "variants": { "minItems": 2 } }
                  }
                }
              }
            }
          }
        },
        {
          "if": { "properties": { "kind": { "const": "convergence" } }, "required": ["kind"] },
          "then": { "required": ["requiredProducts"] }
        },
        {
          "if": { "properties": { "kind": { "const": "terminal" } }, "required": ["kind"] },
          "then": { "required": ["terminalDisposition"] }
        },
        {
          "if": { "properties": { "kind": { "const": "provider-slot" } }, "required": ["kind"] },
          "then": { "required": ["providerSlot"] }
        }
      ]
    },

    "edge": {
      "$comment": "Edge semantics are orthogonal. Topology, contract relation, semantic progress, and selecting variant answer different questions and are never collapsed into one relation enum.",
      "type": "object",
      "additionalProperties": false,
      "required": [
        "edgeId",
        "from",
        "to",
        "topology",
        "semanticPrecedence",
        "projectionOrdinal",
        "bindingAuthority"
      ],
      "properties": {
        "edgeId": { "$ref": "#/$defs/semanticIdentity" },
        "from": { "$ref": "#/$defs/semanticIdentity" },
        "to": { "$ref": "#/$defs/semanticIdentity" },

        "topology": {
          "enum": [
            "TRANSITION",
            "BRANCH_ROUTE",
            "FAN_OUT_MEMBER",
            "CONVERGENCE_REQUIREMENT",
            "ALTITUDE_DESCENT",
            "BOUNDED_RETURN"
          ]
        },

        "contractRelation": {
          "enum": ["SATISFIES", "REQUIRES"],
          "description": "How a product and an Input contract compose. Applicable only to contract edges."
        },

        "semanticProgress": {
          "enum": ["NARROWS", "ESTABLISHES", "TERMINATES", "DESCENDS", "BOUNDED_RETURN"],
          "description": "How meaning advances. Required for every executable forward transition and governed return."
        },

        "selectingVariant": {
          "type": "string",
          "pattern": "^[A-Z][A-Z0-9_]*$",
          "description": "The exact declared Outcome variant that selects this edge."
        },

        "semanticPrecedence": {
          "enum": ["REQUIRED", "INDEPENDENT"],
          "description": "REQUIRED imposes partial order. INDEPENDENT marks peers that need no arbitrary total order; their display order comes from projectionOrdinal alone."
        },

        "projectionOrdinal": { "$ref": "#/$defs/projectionOrdinal" },

        "boundedReturn": {
          "$comment": "A back edge is legitimate only with declared bounded repair, resumption, or iteration authority and an explicit bound.",
          "type": "object",
          "additionalProperties": false,
          "required": ["kind", "bound", "authority"],
          "properties": {
            "kind": { "enum": ["REPAIR", "RESUMPTION", "ITERATION"] },
            "bound": { "type": "integer", "minimum": 1 },
            "authority": { "$ref": "#/$defs/authorityRef" }
          }
        },

        "fanOutSetId": {
          "$comment": "Members sharing a fanOutSetId are jointly required; all must close.",
          "$ref": "#/$defs/semanticIdentity"
        },

        "bindingAuthority": { "$ref": "#/$defs/authorityRef" },

        "observability": { "$ref": "#/$defs/edgeObservabilityObligation" }
      },

      "allOf": [
        {
          "$comment": "A branch route names the exact variant that selected it.",
          "if": { "properties": { "topology": { "const": "BRANCH_ROUTE" } }, "required": ["topology"] },
          "then": { "required": ["selectingVariant", "semanticProgress"] }
        },
        {
          "$comment": "Selecting variant is forbidden where no variant selects the edge.",
          "if": {
            "properties": {
              "topology": {
                "enum": ["TRANSITION", "FAN_OUT_MEMBER", "CONVERGENCE_REQUIREMENT", "ALTITUDE_DESCENT"]
              }
            },
            "required": ["topology"]
          },
          "then": { "not": { "required": ["selectingVariant"] } }
        },
        {
          "$comment": "Executable forward transitions must declare how meaning advances.",
          "if": {
            "properties": {
              "topology": { "enum": ["TRANSITION", "FAN_OUT_MEMBER", "ALTITUDE_DESCENT"] }
            },
            "required": ["topology"]
          },
          "then": { "required": ["semanticProgress"] }
        },
        {
          "$comment": "A convergence requirement is a contract edge, not an executable transition.",
          "if": {
            "properties": { "topology": { "const": "CONVERGENCE_REQUIREMENT" } },
            "required": ["topology"]
          },
          "then": {
            "required": ["contractRelation"],
            "properties": { "contractRelation": { "const": "REQUIRES" } }
          }
        },
        {
          "$comment": "An altitude descent is the only topology that changes altitude.",
          "if": {
            "properties": { "topology": { "const": "ALTITUDE_DESCENT" } },
            "required": ["topology"]
          },
          "then": {
            "properties": { "semanticProgress": { "const": "DESCENDS" } }
          }
        },
        {
          "$comment": "A back edge without declared bounded authority is rejected.",
          "if": {
            "properties": { "topology": { "const": "BOUNDED_RETURN" } },
            "required": ["topology"]
          },
          "then": {
            "required": ["boundedReturn", "semanticProgress"],
            "properties": { "semanticProgress": { "const": "BOUNDED_RETURN" } }
          }
        },
        {
          "$comment": "Fan-out membership is meaningless without its jointly required set.",
          "if": {
            "properties": { "topology": { "const": "FAN_OUT_MEMBER" } },
            "required": ["topology"]
          },
          "then": { "required": ["fanOutSetId"] }
        }
      ]
    },

    "observabilityContract": {
      "$comment": "Every executable cell binds its testimony before physical telemetry realization.",
      "type": "object",
      "additionalProperties": false,
      "required": [
        "checkpoints",
        "semanticAddress",
        "causalAddress",
        "measurements",
        "authorizedDimensions",
        "sampling",
        "evidenceDestination",
        "authority"
      ],
      "properties": {
        "checkpoints": {
          "type": "array",
          "minItems": 1,
          "items": { "$ref": "#/$defs/semanticIdentity" }
        },
        "semanticAddress": { "type": "string", "minLength": 1 },
        "causalAddress": { "type": "string", "minLength": 1 },
        "measurements": {
          "type": "array",
          "minItems": 1,
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": ["measurementId", "unit"],
            "properties": {
              "measurementId": { "$ref": "#/$defs/semanticIdentity" },
              "unit": { "type": "string", "minLength": 1 }
            }
          }
        },
        "authorizedDimensions": {
          "type": "array",
          "items": { "$ref": "#/$defs/semanticIdentity" }
        },
        "sampling": {
          "type": "object",
          "additionalProperties": false,
          "required": ["strategy"],
          "properties": {
            "strategy": { "enum": ["ALWAYS", "RATE", "CONDITIONAL"] },
            "rate": { "type": "number", "minimum": 0, "maximum": 1 },
            "conditionRef": { "$ref": "#/$defs/authorityRef" }
          }
        },
        "evidenceDestination": { "$ref": "#/$defs/semanticIdentity" },
        "authority": { "$ref": "#/$defs/authorityRef" }
      }
    },

    "edgeObservabilityObligation": {
      "type": "object",
      "additionalProperties": false,
      "required": ["checkpoints", "authority"],
      "properties": {
        "checkpoints": {
          "type": "array",
          "minItems": 1,
          "items": { "$ref": "#/$defs/semanticIdentity" }
        },
        "authority": { "$ref": "#/$defs/authorityRef" }
      }
    },

    "sliDefinition": {
      "$comment": "An SLI is constructed only from exact admitted testimony identities. An incidental implementation metric is not an indicator.",
      "type": "object",
      "additionalProperties": false,
      "required": [
        "sliId",
        "testimonyInputs",
        "scope",
        "calculation",
        "window",
        "freshness",
        "unit",
        "missingTestimonyDisposition"
      ],
      "properties": {
        "sliId": { "$ref": "#/$defs/semanticIdentity" },
        "testimonyInputs": {
          "type": "array",
          "minItems": 1,
          "items": { "$ref": "#/$defs/semanticIdentity" }
        },
        "scope": { "type": "string", "minLength": 1 },
        "calculation": { "type": "string", "minLength": 1 },
        "dimensions": {
          "type": "array",
          "items": { "$ref": "#/$defs/semanticIdentity" }
        },
        "window": { "type": "string", "minLength": 1 },
        "freshness": { "type": "string", "minLength": 1 },
        "unit": { "type": "string", "minLength": 1 },
        "missingTestimonyDisposition": {
          "enum": ["INCOMPLETE_EVIDENCE", "EXCLUDE", "FAIL_CLOSED"],
          "description": "A partial evaluation window is never a satisfied production promise."
        }
      }
    },

    "sloDefinition": {
      "type": "object",
      "additionalProperties": false,
      "required": ["sloId", "sliId", "target", "evaluationWindow", "errorBudgetPolicy"],
      "properties": {
        "sloId": { "$ref": "#/$defs/semanticIdentity" },
        "sliId": { "$ref": "#/$defs/semanticIdentity" },
        "target": { "type": "string", "minLength": 1 },
        "evaluationWindow": { "type": "string", "minLength": 1 },
        "errorBudgetPolicy": { "$ref": "#/$defs/authorityRef" },
        "childAllocations": {
          "$comment": "Governed allocation profiles only. A child budget is never inferred from topology or observations.",
          "type": "array",
          "items": {
            "type": "object",
            "additionalProperties": false,
            "required": ["nodeId", "allocation", "authority"],
            "properties": {
              "nodeId": { "$ref": "#/$defs/semanticIdentity" },
              "allocation": { "type": "string", "minLength": 1 },
              "authority": { "$ref": "#/$defs/authorityRef" }
            }
          }
        }
      }
    },

    "slaBoundary": {
      "$comment": "External service obligations bind only at declared boundaries. Contractual leakage into unbound internal mechanics is rejected.",
      "type": "object",
      "additionalProperties": false,
      "required": ["slaId", "authority", "serviceBoundary"],
      "properties": {
        "slaId": { "$ref": "#/$defs/semanticIdentity" },
        "authority": { "$ref": "#/$defs/authorityRef" },
        "serviceBoundary": {
          "enum": [
            "CAPABILITY",
            "PRODUCT",
            "INTERFACE",
            "PLATFORM",
            "PROVIDER",
            "CUSTOMER_EXPERIENCE"
          ]
        },
        "sloIds": {
          "type": "array",
          "minItems": 1,
          "items": { "$ref": "#/$defs/semanticIdentity" }
        }
      }
    },

    "c4Mapping": {
      "type": "object",
      "additionalProperties": false,
      "required": ["elementId", "realizationAuthority"],
      "properties": {
        "elementId": { "$ref": "#/$defs/semanticIdentity" },
        "realizationAuthority": { "$ref": "#/$defs/authorityRef" },
        "nodeIds": {
          "type": "array",
          "items": { "$ref": "#/$defs/semanticIdentity" }
        }
      }
    }
  }
}
';
GO
-- Read schema documents named by declared absolute $ref values. Local fragment
-- references remain in their owning document. Repeated documents terminate the
-- traversal, including mutually recursive schema documents.
CREATE OR ALTER FUNCTION analysis.fn_contract_schema_closure(@content_pk bigint)
RETURNS @closure TABLE(schema_content_pk bigint PRIMARY KEY)
AS
BEGIN
 DECLARE @available TABLE(content_pk bigint, schema_id nvarchar(4000) COLLATE Latin1_General_100_BIN2);
 DECLARE @loaded bit=0;
 DECLARE @pending TABLE(content_pk bigint PRIMARY KEY,visited bit NOT NULL DEFAULT 0);
 INSERT @pending(content_pk) VALUES(@content_pk);
 WHILE EXISTS(SELECT 1 FROM @pending WHERE visited=0)
 BEGIN
  DECLARE @current bigint=(SELECT MIN(content_pk) FROM @pending WHERE visited=0),@document nvarchar(max);
  UPDATE @pending SET visited=1 WHERE content_pk=@current;
  INSERT @closure VALUES(@current);
  SELECT @document=CONVERT(nvarchar(max),CONVERT(varchar(max),content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)
  FROM source.content_object WHERE content_object_pk=@current;
  DECLARE @nodes TABLE(ordinal int IDENTITY,document nvarchar(max));
  DELETE @nodes;
  IF CHARINDEX('"$ref"',@document)>0 INSERT @nodes(document) VALUES(@document);
  WHILE EXISTS(SELECT 1 FROM @nodes)
  BEGIN
   DECLARE @ordinal int=(SELECT MIN(ordinal) FROM @nodes),@node nvarchar(max);
   SELECT @node=document FROM @nodes WHERE ordinal=@ordinal;
   DELETE @nodes WHERE ordinal=@ordinal;
   IF @loaded=0 AND EXISTS(SELECT 1 FROM OPENJSON(@node) WHERE [key]='$ref' AND type=1 AND value LIKE '%://%')
   BEGIN
    INSERT @available
    SELECT DISTINCT so.content_object_pk,JSON_VALUE(text.document,'$."$id"')
    FROM source.current_model cm
    JOIN analysis.v_selected_semantic_definition d ON d.estate_model_pk=cm.estate_model_pk AND d.object_kind='CONTRACT'
    JOIN model.contract_version cv ON cv.semantic_object_definition_pk=d.semantic_object_definition_pk
    JOIN model.schema_object so ON so.schema_object_pk=cv.schema_object_pk
    JOIN source.content_object co ON co.content_object_pk=so.content_object_pk
    CROSS APPLY(SELECT CONVERT(nvarchar(max),CONVERT(varchar(max),co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS document) text;
    SET @loaded=1;
   END;
   INSERT @pending(content_pk)
   SELECT DISTINCT a.content_pk FROM OPENJSON(@node) member
   JOIN @available a ON a.schema_id=LEFT(member.value,CHARINDEX('#',member.value+'#')-1) COLLATE Latin1_General_100_BIN2
   WHERE member.[key]='$ref' AND member.type=1 AND member.value LIKE '%://%'
    AND NOT EXISTS(SELECT 1 FROM @pending p WHERE p.content_pk=a.content_pk);
   INSERT @nodes(document) SELECT value FROM OPENJSON(@node) WHERE type IN(4,5) AND CHARINDEX('"$ref"',value)>0;
  END;
 END;
 RETURN;
END;
GO
CREATE OR ALTER VIEW analysis.v_capability_execution_declaration AS
WITH cap AS (
  SELECT ec.estate_model_pk, c.capability_pk, c.capability_id COLLATE Latin1_General_100_BIN2 AS capability_id,
         ec.capability_version_pk, ec.semantic_object_definition_pk AS cap_sod
  FROM source.current_model cm
  JOIN model.estate_capability ec ON ec.estate_model_pk = cm.estate_model_pk
  JOIN model.capability c ON c.capability_pk = ec.capability_pk
),
def AS (
  SELECT sod, object_kind, declared_id, namespace_pk, semantic_object_pk, envelope
  FROM (
    SELECT d.semantic_object_definition_pk AS sod, d.object_kind, s.declared_id, s.namespace_pk, s.semantic_object_pk,
           CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS envelope,
           ROW_NUMBER() OVER (PARTITION BY d.semantic_object_pk ORDER BY d.semantic_object_definition_pk DESC) AS rn
    FROM model.semantic_object_definition d
    JOIN model.semantic_object s ON s.semantic_object_pk = d.semantic_object_pk
    JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
  ) x WHERE rn = 1
),
capdef AS (
  SELECT cap.capability_id, def.envelope
  FROM cap JOIN def ON def.sod = cap.cap_sod
),
cli AS (
  SELECT cap.capability_id, JSON_QUERY(capdef.envelope, '$.semantics.cli') AS configuration
  FROM cap JOIN capdef ON capdef.capability_id = cap.capability_id
),
directcontract AS (
  SELECT x.capability_id, x.contract_id, x.schema_content_pk
  FROM (
    SELECT cap.capability_id, ct.contract_id, so.content_object_pk AS schema_content_pk,
           ROW_NUMBER() OVER (PARTITION BY cap.capability_id, ct.contract_id ORDER BY sv.scenario_version_pk DESC, cv.contract_version_pk DESC) AS rn
    FROM cap
    JOIN model.capability_scenario cs ON cs.capability_version_pk = cap.capability_version_pk
    JOIN analysis.v_scenario_invocation_closure c ON c.selected_scenario_version_pk = cs.scenario_version_pk
    JOIN model.scenario_version sv ON sv.scenario_version_pk = c.downstream_scenario_version_pk
    LEFT JOIN model.scenario_input si ON si.scenario_version_pk = sv.scenario_version_pk
    LEFT JOIN model.scenario_outcome_contract soc ON soc.scenario_version_pk = sv.scenario_version_pk
    JOIN model.contract_version cv ON cv.contract_version_pk IN (si.input_contract_version_pk, soc.contract_version_pk)
    JOIN model.contract ct ON ct.contract_pk = cv.contract_pk
    JOIN model.schema_object so ON so.schema_object_pk = cv.schema_object_pk
  ) x WHERE x.rn = 1
),
capcontract AS (
 SELECT capability_id,contract_id,schema_content_pk FROM directcontract
 UNION
 SELECT DISTINCT direct.capability_id,ct.contract_id,closure.schema_content_pk
 FROM directcontract direct
 CROSS APPLY analysis.fn_contract_schema_closure(direct.schema_content_pk) closure
 JOIN model.schema_object so ON so.content_object_pk=closure.schema_content_pk
 JOIN model.contract_version cv ON cv.schema_object_pk=so.schema_object_pk
 JOIN model.contract ct ON ct.contract_pk=cv.contract_pk
 JOIN analysis.v_selected_semantic_definition selected ON selected.semantic_object_definition_pk=cv.semantic_object_definition_pk
  AND selected.estate_model_pk=(SELECT estate_model_pk FROM source.current_model WHERE singleton_id=1)
 WHERE closure.schema_content_pk<>direct.schema_content_pk
),
-- Every capability whose Scenarios appear in this capability's declared invocation
-- closure, including the capability itself. A referenced capability's Ports and
-- Transformations become part of the consuming capability's declaration so the
-- planner can render a composed Scenario without a second declaration read.
reach AS (
  SELECT DISTINCT cap.capability_id,
    (N'sidefx:capability:' + dc.capability_id) COLLATE Latin1_General_100_BIN2 AS namespace_id
  FROM cap
  JOIN model.capability_scenario cs ON cs.capability_version_pk = cap.capability_version_pk
  JOIN analysis.v_scenario_invocation_closure c ON c.capability_version_pk = cap.capability_version_pk AND c.selected_scenario_version_pk = cs.scenario_version_pk
  JOIN model.scenario_version dsv ON dsv.scenario_version_pk = c.downstream_scenario_version_pk
  JOIN model.scenario ds ON ds.scenario_pk = dsv.scenario_pk
  JOIN model.capability dc ON dc.capability_pk = ds.capability_pk
),
reachable AS (
  SELECT DISTINCT cap.capability_id,
    CONVERT(nvarchar(400), JSON_VALUE(op.value, '$.portId')) COLLATE Latin1_General_100_BIN2 AS port_id
  FROM cap
  JOIN model.capability_scenario cs ON cs.capability_version_pk = cap.capability_version_pk
  JOIN analysis.v_scenario_invocation_closure c ON c.selected_scenario_version_pk = cs.scenario_version_pk
  JOIN model.scenario_event se ON se.scenario_version_pk = c.downstream_scenario_version_pk
  JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk = se.execution_authority_version_pk
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = eav.semantic_object_definition_pk
  JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
  CROSS APPLY OPENJSON(CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.authority.operations') op
  WHERE JSON_VALUE(op.value, '$.portId') IS NOT NULL
)
-- capability.authority.json
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/capability.authority.json') COLLATE Latin1_General_100_BIN2 AS source_path,
  N'capability.authority.json' COLLATE Latin1_General_100_BIN2 AS entry_id,
  (JSON_QUERY(capdef.envelope, '$.semantics.authority')) COLLATE Latin1_General_100_BIN2 AS document
FROM cap JOIN capdef ON capdef.capability_id = cap.capability_id
UNION ALL
-- execution-authorities.authority.json
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/execution-authorities.authority.json') COLLATE Latin1_General_100_BIN2,
  N'execution-authorities.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"authorityType":"execution-authorities.v1","executionAuthorities":['
   + ISNULL((SELECT STRING_AGG(JSON_QUERY(x.env, '$.semantics.authority'), N',')
             FROM (
               SELECT DISTINCT eav.execution_authority_version_pk,
                 CONVERT(nvarchar(max), CONVERT(varchar(max), co.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS env
               FROM model.capability_scenario cs
               JOIN analysis.v_scenario_invocation_closure c ON c.selected_scenario_version_pk = cs.scenario_version_pk
               JOIN model.scenario_event se ON se.scenario_version_pk = c.downstream_scenario_version_pk
               JOIN model.execution_authority_version eav ON eav.execution_authority_version_pk = se.execution_authority_version_pk
               JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = eav.semantic_object_definition_pk
               JOIN source.content_object co ON co.content_object_pk = d.canonical_content_pk
               WHERE cs.capability_version_pk = cap.capability_version_pk
             ) x), N'') + N']}') COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- semantic-transformation.authority.json
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/semantic-transformation.authority.json') COLLATE Latin1_General_100_BIN2,
  N'semantic-transformation.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"authorityType":"semantic-transformation-authority.v1","transformations":['
   + ISNULL((SELECT STRING_AGG(JSON_QUERY(def.envelope, '$.semantics'), N',')
             FROM def JOIN model.transformation t ON t.semantic_object_pk = def.semantic_object_pk
             JOIN model.identity_namespace n ON n.namespace_pk = t.namespace_pk
             WHERE n.namespace_id COLLATE Latin1_General_100_BIN2 IN (SELECT r.namespace_id FROM reach r WHERE r.capability_id = cap.capability_id)), N'') + N']}') COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- semantic-graph.authority.json (assembled; no separate declaration)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/semantic-graph.authority.json') COLLATE Latin1_General_100_BIN2,
  N'semantic-graph.authority.json' COLLATE Latin1_General_100_BIN2,
  N'{"transitions":[]}' COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- interfaces.authority.json: CLI interface (configuration from the model declaration),
-- contract catalog, port bindings from PORT declarations.
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/interfaces.authority.json') COLLATE Latin1_General_100_BIN2,
  N'interfaces.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"interfaceAuthorityType":"consumer-interface-authority.v1","contractValidatorCapabilityId":"sda-schema-contract-admission.v1","contractCatalog":"contracts/contract-catalog.json","interfaces":[{"interfaceId":"'
   + cap.capability_id + N'-cli","kind":"cli","rootScenarioId":"' + cap.capability_id + N'","platformCapabilityId":"sda-json-cli.v1"'
   + CASE WHEN cli.configuration IS NULL THEN N'' ELSE N',"configuration":' + CONVERT(nvarchar(max), cli.configuration) END
   + N'}],"portBindings":['
   + ISNULL((SELECT STRING_AGG(JSON_QUERY(def.envelope, '$.semantics'), N',')
             FROM def JOIN model.port p ON p.semantic_object_pk = def.semantic_object_pk
             JOIN model.identity_namespace n ON n.namespace_pk = p.namespace_pk
             WHERE n.namespace_id COLLATE Latin1_General_100_BIN2 IN (SELECT r.namespace_id FROM reach r WHERE r.capability_id = cap.capability_id)), N'') + N'],"projectionBindings":[]}') COLLATE Latin1_General_100_BIN2
FROM cap JOIN cli ON cli.capability_id = cap.capability_id
UNION ALL
-- consumer-workspace.authority.json (assembled from the capability's members)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/consumer-workspace.authority.json') COLLATE Latin1_General_100_BIN2,
  N'consumer-workspace.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"workspaceType":"consumer-workspace-authority.v1","consumerId":"' + cap.capability_id + N'","projectionTargets":["node"],'
   + N'"capabilities":[{"featureId":"' + cap.capability_id + N'.feature","feature":"capability.feature","capability":"capability.authority.json",'
   + N'"semanticGraph":"semantic-graph.authority.json","executionAuthorities":"execution-authorities.authority.json",'
   + N'"interfaces":"interfaces.authority.json","fixtures":"fixtures.authority.json"}]}') COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- capabilities/<id>/capability.feature (one text per capability: the declared
-- feature's current version, preferring the parsed declaration over the retained
-- text carrier; text resolved by the declaration's content_digest)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/capability.feature') COLLATE Latin1_General_100_BIN2,
  N'capability.feature' COLLATE Latin1_General_100_BIN2,
  x.text COLLATE Latin1_General_100_BIN2
FROM cap
OUTER APPLY (
  SELECT TOP 1 CONVERT(nvarchar(max), CONVERT(varchar(max), fco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8) AS text
  FROM model.capability c2
  JOIN model.feature_version fv ON fv.feature_pk = c2.feature_pk
  JOIN model.semantic_object_definition d ON d.semantic_object_definition_pk = fv.semantic_object_definition_pk
  JOIN source.content_object env ON env.content_object_pk = d.canonical_content_pk
  JOIN source.content_object fco ON fco.content_digest = CONVERT(binary(32), N'0x' + JSON_VALUE(CONVERT(nvarchar(max), CONVERT(varchar(max), env.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8), '$.semantics.content_digest'), 1)
  WHERE c2.capability_pk = cap.capability_pk
  ORDER BY CASE fv.source_profile WHEN N'parsed-feature-declaration.v1' THEN 0 WHEN N'retained-feature-binding.v1' THEN 1 ELSE 2 END,
           fv.feature_version_pk DESC
) x
WHERE x.text IS NOT NULL
UNION ALL
-- contracts/contract-catalog.json
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/contracts/contract-catalog.json') COLLATE Latin1_General_100_BIN2,
  N'contracts/contract-catalog.json' COLLATE Latin1_General_100_BIN2,
  (N'{' + ISNULL((SELECT STRING_AGG(N'"' + cc.contract_id + N'":"' + cc.contract_id + N'.schema.json"', N',')
                  FROM capcontract cc WHERE cc.capability_id = cap.capability_id), N'') + N'}') COLLATE Latin1_General_100_BIN2
FROM cap
UNION ALL
-- contracts/<id>.schema.json (schema bytes resolved by the contract's schema object)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/contracts/' + cc.contract_id + N'.schema.json') COLLATE Latin1_General_100_BIN2,
  (N'contracts/' + cc.contract_id + N'.schema.json') COLLATE Latin1_General_100_BIN2,
  (CONVERT(nvarchar(max), CONVERT(varchar(max), sco.content_bytes) COLLATE Latin1_General_100_BIN2_UTF8)) COLLATE Latin1_General_100_BIN2
FROM cap JOIN capcontract cc ON cc.capability_id = cap.capability_id
JOIN source.content_object sco ON sco.content_object_pk = cc.schema_content_pk
UNION ALL
-- fixtures.authority.json (assembled from FIXTURE declarations owned by the capability)
SELECT cap.estate_model_pk, cap.capability_id,
  (N'capabilities/' + cap.capability_id + N'/fixtures.authority.json') COLLATE Latin1_General_100_BIN2,
  N'fixtures.authority.json' COLLATE Latin1_General_100_BIN2,
  (N'{"fixtureType":"consumer-capability-fixtures.v1","fixtures":['
   + ISNULL((SELECT STRING_AGG(JSON_QUERY(def.envelope, '$.semantics.fixture'), N',')
             FROM def JOIN model.fixture fx ON fx.semantic_object_definition_pk = def.sod
             WHERE fx.owner_definition_pk = cap.cap_sod), N'') + N']}') COLLATE Latin1_General_100_BIN2
FROM cap;
GO
SELECT 'contract_catalog' AS result_set,document FROM analysis.v_capability_execution_declaration WHERE capability_id='admit-canonical-circuit-blueprint' AND entry_id='contracts/contract-catalog.json';
COMMIT TRANSACTION;
