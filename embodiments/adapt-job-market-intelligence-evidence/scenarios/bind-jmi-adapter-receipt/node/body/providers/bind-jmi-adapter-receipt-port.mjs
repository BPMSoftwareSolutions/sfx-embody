// Generated from capabilities/adapt-job-market-intelligence-evidence/semantic-transformation.authority.json; sha256:2b167eaf1093228810925754bece447ce574863a6ca8f5459be9e681f3972803
import { crypto } from "./native-mechanics.mjs";
export class BindJmiAdapterReceiptPort {
  execute(input, root = input) {
    return (() => {
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
                  ["adaptationDisposition"]: input?.adaptationDisposition,
                }),
              ),
            )
            .digest("hex"),
        ),
      );
      return Object.assign({}, input, { ["adapterReceiptDigest"]: adapterReceiptDigest });
    })();
  }
}
