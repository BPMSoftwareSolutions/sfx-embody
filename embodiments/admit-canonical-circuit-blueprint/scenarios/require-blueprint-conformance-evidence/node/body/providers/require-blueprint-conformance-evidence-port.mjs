// Generated from capabilities/admit-canonical-circuit-blueprint/semantic-transformation.authority.json; sha256:edd662a3271af9b23645ff2b0c6e263a053ed6cfe149d09add4a8fe6f9b15f93
export class RequireBlueprintConformanceEvidencePort {
  execute(input, root = input) {
    return (() => {
      const checksClosed = [
        input?.payload?.capabilityId === input?.payload?.candidate?.capability?.capabilityId,
        input?.payload?.featureDigest ===
          input?.payload?.candidate?.sourceAuthority?.featureAuthorityRef?.digest,
        input?.payload?.candidate?.sourceAuthority?.disposition === "CANDIDATE",
        input?.payload?.conformanceEvidence?.evidenceVersion ===
          "canonical-blueprint-conformance-evidence.v1",
        input?.payload?.conformanceEvidence?.blueprintAuthorityDigest ===
          input?.payload?.candidate?.blueprintAuthority?.authorityDigest,
        input?.payload?.conformanceEvidence?.carrierDigest ===
          input?.payload?.candidateCarrierDigest,
        input?.payload?.conformanceEvidence?.schemaAuthority?.digest ===
          input?.payload?.canonicalSchemaDigest,
        input?.payload?.conformanceEvidence?.disposition === "CONFORMS",
        (input?.payload?.conformanceEvidence?.findings).length === 0,
      ].every((condition) => Boolean(condition));
      const obligationFindings = [
        input?.payload?.capabilityId === input?.payload?.candidate?.capability?.capabilityId
          ? []
          : [
              {
                ["code"]: "TARGET_CAPABILITY_ID_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        input?.payload?.featureDigest ===
        input?.payload?.candidate?.sourceAuthority?.featureAuthorityRef?.digest
          ? []
          : [
              {
                ["code"]: "TARGET_FEATURE_AUTHORITY_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        input?.payload?.candidate?.sourceAuthority?.disposition === "CANDIDATE"
          ? []
          : [
              {
                ["code"]: "CANDIDATE_SOURCE_DISPOSITION_NOT_CANDIDATE",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        input?.payload?.conformanceEvidence?.evidenceVersion ===
        "canonical-blueprint-conformance-evidence.v1"
          ? []
          : [
              {
                ["code"]: "CONFORMANCE_EVIDENCE_CONTRACT_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        input?.payload?.conformanceEvidence?.blueprintAuthorityDigest ===
        input?.payload?.candidate?.blueprintAuthority?.authorityDigest
          ? []
          : [
              {
                ["code"]: "CONFORMANCE_EVIDENCE_BLUEPRINT_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        input?.payload?.conformanceEvidence?.carrierDigest ===
        input?.payload?.candidateCarrierDigest
          ? []
          : [
              {
                ["code"]: "CONFORMANCE_EVIDENCE_CARRIER_DIGEST_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        input?.payload?.conformanceEvidence?.schemaAuthority?.digest ===
        input?.payload?.canonicalSchemaDigest
          ? []
          : [
              {
                ["code"]: "CONFORMANCE_SCHEMA_AUTHORITY_DIVERGED",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        input?.payload?.conformanceEvidence?.disposition === "CONFORMS"
          ? []
          : [
              {
                ["code"]: "CONFORMANCE_DISPOSITION_NOT_CONFORMING",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
        (input?.payload?.conformanceEvidence?.findings).length === 0
          ? []
          : [
              {
                ["code"]: "CONFORMANCE_EVIDENCE_HAS_FINDINGS",
                ["blueprintCellId"]: "require-blueprint-conformance-evidence",
              },
            ],
      ].flatMap((findingGroup, findingGroupIndex) => findingGroup);
      return Object.assign({}, input, {
        ["payload"]: Object.assign({}, input?.payload, {
          ["require-blueprint-conformance-evidenceDisposition"]: {
            ["disposition"]: checksClosed ? "MET" : "UNMET",
            ["blueprintCellId"]: "require-blueprint-conformance-evidence",
            ["findings"]: obligationFindings,
          },
        }),
      });
    })();
  }
}
