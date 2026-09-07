// Generated from capabilities/adapt-job-market-intelligence-evidence/semantic-transformation.authority.json; sha256:2b167eaf1093228810925754bece447ce574863a6ca8f5459be9e681f3972803
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
      ].includes(input?.jmiRecordType);
      const authorityBound = [
        input?.adapterAuthorityId === "sidefx-jmi-adapter-authority.v1",
        input?.adapterAuthorityDigest === "" ? false : true,
      ].every((check) => Boolean(check));
      const admitted = [typeAdmitted, authorityBound].every((check$binding) =>
        Boolean(check$binding),
      );
      return Object.assign({}, input, { ["typeAdmissionResult"]: { ["admitted"]: admitted } });
    })();
  }
}
