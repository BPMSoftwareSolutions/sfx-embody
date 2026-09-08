// Generated from capabilities/adapt-job-market-intelligence-evidence/semantic-transformation.authority.json; sha256:2b167eaf1093228810925754bece447ce574863a6ca8f5459be9e681f3972803
import { sfxEquals, sfxMerge, sfxTruthy, sfxValueAt } from "./native-mechanics.mjs";
export class VerifyJmiRecordBindingPort {
  execute(input, root = input) {
    return (() => {
      const bound = [
        sfxTruthy(sfxEquals(sfxValueAt(input, "jmiRecordRef"), "")) ? false : true,
        sfxTruthy(sfxEquals(sfxValueAt(input, "jmiRecordDigest"), "")) ? false : true,
      ].every((check) => sfxTruthy(sfxValueAt(check, "")));
      return sfxMerge(sfxValueAt(input, ""), {
        ["recordBindingResult"]: { ["bound"]: sfxValueAt(bound, "") },
      });
    })();
  }
}
