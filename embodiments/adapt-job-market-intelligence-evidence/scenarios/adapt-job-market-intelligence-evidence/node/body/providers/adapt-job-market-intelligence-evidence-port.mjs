// Generated from capabilities/adapt-job-market-intelligence-evidence/semantic-transformation.authority.json; sha256:2b167eaf1093228810925754bece447ce574863a6ca8f5459be9e681f3972803
import {
  crypto,
  sfxEquals,
  sfxFormat,
  sfxMerge,
  sfxTruthy,
  sfxValueAt,
} from "./native-mechanics.mjs";
export class AdaptJobMarketIntelligenceEvidencePort {
  execute(input, root = input) {
    return (() => {
      const recordBound = [
        sfxTruthy(sfxEquals(sfxValueAt(input, "jmiRecordRef"), "")) ? false : true,
        sfxTruthy(sfxEquals(sfxValueAt(input, "jmiRecordDigest"), "")) ? false : true,
      ].every((check) => sfxTruthy(sfxValueAt(check, "")));
      const typeAdmitted = [
        "job-market-observation-scope.v1",
        "job-market-intelligence-state.v1",
        "job-market-observation-request.v1",
        "public-job-market-observation-state.v1",
        "experience-admission-scope.v1",
        "experience-gap-resolution-scope.v1",
        "market-driven-experience-acquisition-scope.v1",
        "experience-mission-planning-scope.v1",
      ].includes(sfxValueAt(input, "jmiRecordType"));
      const authorityBound = [
        sfxEquals(sfxValueAt(input, "adapterAuthorityId"), "sidefx-jmi-adapter-authority.v1"),
        sfxTruthy(sfxEquals(sfxValueAt(input, "adapterAuthorityDigest"), "")) ? false : true,
      ].every((check$binding) => sfxTruthy(sfxValueAt(check$binding, "")));
      const windowDeclared = sfxTruthy(sfxEquals(sfxValueAt(input, "observedWindow"), ""))
        ? false
        : true;
      const adaptationDisposition = sfxTruthy(sfxEquals(sfxValueAt(recordBound, ""), false))
        ? "ADAPTATION_HELD"
        : sfxTruthy(sfxEquals(sfxValueAt(typeAdmitted, ""), false))
          ? "ADAPTATION_HELD"
          : sfxTruthy(sfxEquals(sfxValueAt(authorityBound, ""), false))
            ? "ADAPTATION_HELD"
            : sfxTruthy(sfxEquals(sfxValueAt(windowDeclared, ""), false))
              ? "ADAPTATION_HELD"
              : "ADAPTED_EVIDENCE_BINDING";
      const findingCodes = sfxTruthy(sfxEquals(sfxValueAt(recordBound, ""), false))
        ? ["JMI_RECORD_UNBOUND"]
        : sfxTruthy(sfxEquals(sfxValueAt(typeAdmitted, ""), false))
          ? ["JMI_RECORD_TYPE_UNADMITTED"]
          : sfxTruthy(sfxEquals(sfxValueAt(authorityBound, ""), false))
            ? ["ADAPTER_AUTHORITY_UNADMITTED"]
            : sfxTruthy(sfxEquals(sfxValueAt(windowDeclared, ""), false))
              ? ["OBSERVATION_WINDOW_ABSENT"]
              : [];
      const adapterReceiptDigest = sfxFormat("sha256:{digest}", {
        ["digest"]: crypto
          .createHash("sha256")
          .update(
            String(
              JSON.stringify({
                ["jmiRecordRef"]: sfxValueAt(input, "jmiRecordRef"),
                ["jmiRecordType"]: sfxValueAt(input, "jmiRecordType"),
                ["jmiRecordDigest"]: sfxValueAt(input, "jmiRecordDigest"),
                ["adaptationDisposition"]: sfxValueAt(adaptationDisposition, ""),
              }),
            ),
          )
          .digest("hex"),
      });
      return sfxMerge(sfxValueAt(input, ""), {
        ["contractId"]: "job-market-intelligence-adapter-record.v1",
        ["adaptationDisposition"]: sfxValueAt(adaptationDisposition, ""),
        ["findingCodes"]: sfxValueAt(findingCodes, ""),
        ["adapterReceiptDigest"]: sfxValueAt(adapterReceiptDigest, ""),
      });
    })();
  }
}
