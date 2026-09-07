// Generated from capabilities/adapt-job-market-intelligence-evidence/semantic-transformation.authority.json; sha256:2b167eaf1093228810925754bece447ce574863a6ca8f5459be9e681f3972803
import { crypto } from "./native-mechanics.mjs";
export class AdaptJobMarketIntelligenceEvidencePort {
  execute(input, root = input) {
    return (() => {
      const recordBound = [
        input?.jmiRecordRef === "" ? false : true,
        input?.jmiRecordDigest === "" ? false : true,
      ].every((check) => Boolean(check));
      const typeAdmitted = [
        "job-market-observation-scope.v1",
        "job-market-intelligence-state.v1",
        "job-market-observation-request.v1",
        "public-job-market-observation-state.v1",
        "experience-admission-scope.v1",
        "experience-gap-resolution-scope.v1",
        "market-driven-experience-acquisition-scope.v1",
        "experience-mission-planning-scope.v1",
      ].includes(input?.jmiRecordType);
      const authorityBound = [
        input?.adapterAuthorityId === "sidefx-jmi-adapter-authority.v1",
        input?.adapterAuthorityDigest === "" ? false : true,
      ].every((check$binding) => Boolean(check$binding));
      const windowDeclared = input?.observedWindow === "" ? false : true;
      const adaptationDisposition =
        recordBound === false
          ? "ADAPTATION_HELD"
          : typeAdmitted === false
            ? "ADAPTATION_HELD"
            : authorityBound === false
              ? "ADAPTATION_HELD"
              : windowDeclared === false
                ? "ADAPTATION_HELD"
                : "ADAPTED_EVIDENCE_BINDING";
      const findingCodes =
        recordBound === false
          ? ["JMI_RECORD_UNBOUND"]
          : typeAdmitted === false
            ? ["JMI_RECORD_TYPE_UNADMITTED"]
            : authorityBound === false
              ? ["ADAPTER_AUTHORITY_UNADMITTED"]
              : windowDeclared === false
                ? ["OBSERVATION_WINDOW_ABSENT"]
                : [];
      const adapterReceiptDigest = "sha256:{digest}".replaceAll(
        "{digest}",
        String(
          crypto
            .createHash("sha256")
            .update(
              String(
                JSON.stringify({
                  ["jmiRecordRef"]: input?.jmiRecordRef,
                  ["jmiRecordType"]: input?.jmiRecordType,
                  ["jmiRecordDigest"]: input?.jmiRecordDigest,
                  ["adaptationDisposition"]: adaptationDisposition,
                }),
              ),
            )
            .digest("hex"),
        ),
      );
      return Object.assign({}, input, {
        ["contractId"]: "job-market-intelligence-adapter-record.v1",
        ["adaptationDisposition"]: adaptationDisposition,
        ["findingCodes"]: findingCodes,
        ["adapterReceiptDigest"]: adapterReceiptDigest,
      });
    })();
  }
}
