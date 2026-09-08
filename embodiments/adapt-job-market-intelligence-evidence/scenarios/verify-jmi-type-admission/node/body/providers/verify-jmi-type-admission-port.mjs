// Generated from capabilities/adapt-job-market-intelligence-evidence/semantic-transformation.authority.json; sha256:2b167eaf1093228810925754bece447ce574863a6ca8f5459be9e681f3972803
import { sfxEquals, sfxMerge, sfxTruthy, sfxValueAt } from "./native-mechanics.mjs";
export class VerifyJmiTypeAdmissionPort {
  execute(input, root = input) {
    return (() => {
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
      ].every((check) => sfxTruthy(sfxValueAt(check, "")));
      const admitted = [sfxValueAt(typeAdmitted, ""), sfxValueAt(authorityBound, "")].every(
        (check$binding) => sfxTruthy(sfxValueAt(check$binding, "")),
      );
      return sfxMerge(sfxValueAt(input, ""), {
        ["typeAdmissionResult"]: { ["admitted"]: sfxValueAt(admitted, "") },
      });
    })();
  }
}
