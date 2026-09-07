// Generated from capabilities/adapt-job-market-intelligence-evidence/semantic-transformation.authority.json; sha256:2b167eaf1093228810925754bece447ce574863a6ca8f5459be9e681f3972803
export class VerifyJmiRecordBindingPort {
  execute(input, root = input) {
    return (() => {
      const bound = [
        input?.jmiRecordRef === "" ? false : true,
        input?.jmiRecordDigest === "" ? false : true,
      ].every((check) => Boolean(check));
      return Object.assign({}, input, { ["recordBindingResult"]: { ["bound"]: bound } });
    })();
  }
}
