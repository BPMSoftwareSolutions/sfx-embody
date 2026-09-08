// Generated from capabilities/adapt-job-market-intelligence-evidence/semantic-transformation.authority.json; sha256:2b167eaf1093228810925754bece447ce574863a6ca8f5459be9e681f3972803
import { crypto, sfxFormat, sfxMerge, sfxValueAt } from "./native-mechanics.mjs";
export class BindJmiAdapterReceiptPort {
  execute(input, root = input) {
    return (() => {
      const adapterReceiptDigest = sfxFormat("sha256:{digest}", {
        ["digest"]: crypto
          .createHash("sha256")
          .update(
            String(
              JSON.stringify({
                ["jmiRecordRef"]: sfxValueAt(input, "jmiRecordRef"),
                ["jmiRecordType"]: sfxValueAt(input, "jmiRecordType"),
                ["jmiRecordDigest"]: sfxValueAt(input, "jmiRecordDigest"),
                ["adaptationDisposition"]: sfxValueAt(input, "adaptationDisposition"),
              }),
            ),
          )
          .digest("hex"),
      });
      return sfxMerge(sfxValueAt(input, ""), {
        ["adapterReceiptDigest"]: sfxValueAt(adapterReceiptDigest, ""),
      });
    })();
  }
}
