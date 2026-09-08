// Generated from capabilities/resolve-sidefx-eligible-providers/semantic-transformation.authority.json; sha256:27abab599fb60064581bd8ef647a054059d157a4659503178a679e96169ff89d
import {
  crypto,
  sfxEquals,
  sfxFormat,
  sfxGreaterThan,
  sfxLength,
  sfxMerge,
  sfxTruthy,
  sfxValueAt,
} from "./native-mechanics.mjs";
export class ResolveSidefxEligibleProvidersPort {
  execute(input, root = input) {
    return (() => {
      const consideredProviders = sfxValueAt(input, "providerBindings").map(
        (binding, bindingIndex) =>
          (() => {
            const capabilityMatches = sfxEquals(
              sfxValueAt(binding, "platformCapabilityId"),
              sfxValueAt(input, "requestedPlatformCapabilityId"),
            );
            const isAdmitted = sfxEquals(sfxValueAt(binding, "lifecycle"), "ADMITTED");
            const conformanceIsAdmitted = sfxValueAt(input, "conformantDispositions").includes(
              sfxValueAt(binding, "conformanceDisposition"),
            );
            const targetIsDeclared = sfxValueAt(binding, "declaredTargets").includes(
              sfxValueAt(input, "requestedTarget"),
            );
            const evaluation = sfxTruthy(sfxValueAt(capabilityMatches, ""))
              ? sfxTruthy(sfxValueAt(isAdmitted, ""))
                ? sfxTruthy(sfxValueAt(conformanceIsAdmitted, ""))
                  ? sfxTruthy(sfxValueAt(targetIsDeclared, ""))
                    ? {
                        ["disposition"]: "ELIGIBLE",
                        ["reasonCode"]: "ADMITTED_CONFORMANT_AND_TARGET_DECLARED",
                      }
                    : {
                        ["disposition"]: "NOT_OBSERVABLE",
                        ["reasonCode"]: "TARGET_NOT_DECLARED_BY_BINDING",
                      }
                  : {
                      ["disposition"]: "NOT_OBSERVABLE",
                      ["reasonCode"]: "CONFORMANCE_EVIDENCE_ABSENT",
                    }
                : { ["disposition"]: "INELIGIBLE", ["reasonCode"]: "PROVIDER_NOT_ADMITTED" }
              : {
                  ["disposition"]: "NOT_APPLICABLE",
                  ["reasonCode"]: "PLATFORM_CAPABILITY_MISMATCH",
                };
            return {
              ["authorityBindings"]: sfxValueAt(binding, "authorityBindings"),
              ["conformanceDisposition"]: sfxValueAt(binding, "conformanceDisposition"),
              ["conformanceReceiptDigest"]: sfxValueAt(binding, "conformanceReceiptDigest"),
              ["conformanceReceiptRef"]: sfxValueAt(binding, "conformanceReceiptRef"),
              ["eligibilityDisposition"]: sfxValueAt(evaluation, "disposition"),
              ["lifecycle"]: sfxValueAt(binding, "lifecycle"),
              ["platformCapabilityId"]: sfxValueAt(binding, "platformCapabilityId"),
              ["providerAuthorityDigest"]: sfxValueAt(binding, "providerAuthorityDigest"),
              ["providerAuthorityId"]: sfxValueAt(binding, "providerAuthorityId"),
              ["providerAuthorityRef"]: sfxValueAt(binding, "providerAuthorityRef"),
              ["providerBindingDigest"]: sfxValueAt(binding, "providerBindingDigest"),
              ["providerBindingRef"]: sfxValueAt(binding, "providerBindingRef"),
              ["reasonCode"]: sfxValueAt(evaluation, "reasonCode"),
            };
          })(),
      );
      const eligibleProviders = sfxValueAt(consideredProviders, "").filter(
        (provider, providerIndex) =>
          sfxTruthy(sfxEquals(sfxValueAt(provider, "eligibilityDisposition"), "ELIGIBLE")),
      );
      const undeclaredTargetProviders = sfxValueAt(consideredProviders, "").filter(
        (provider$binding, providerIndex$binding) =>
          sfxTruthy(
            sfxEquals(sfxValueAt(provider$binding, "reasonCode"), "TARGET_NOT_DECLARED_BY_BINDING"),
          ),
      );
      const undeclaredTargetFindings = sfxValueAt(undeclaredTargetProviders, "").map(
        (provider$binding$binding, providerIndex$binding$binding) => ({
          ["code"]: "PROVIDER_TARGET_NOT_DECLARED",
          ["message"]: sfxFormat(
            "Provider authority {id} is admitted and conformant but declares no projection target, so its eligibility for the requested target is not observable.",
            { ["id"]: sfxValueAt(provider$binding$binding, "providerAuthorityId") },
          ),
          ["ruleId"]: "sidefx-semantic-provider-eligibility.v1",
          ["severity"]: "WARNING",
          ["sourcePointer"]: "",
          ["sourceRef"]: sfxValueAt(provider$binding$binding, "providerBindingRef"),
        }),
      );
      const resolutionSubject = {
        ["consideredCount"]: sfxLength(sfxValueAt(consideredProviders, "")),
        ["disposition"]: sfxTruthy(sfxGreaterThan(sfxLength(sfxValueAt(eligibleProviders, "")), 0))
          ? "PROVIDERS_RESOLVED"
          : "NOT_OBSERVABLE",
        ["eligibleCount"]: sfxLength(sfxValueAt(eligibleProviders, "")),
        ["findings"]: sfxValueAt(undeclaredTargetFindings, ""),
        ["providers"]: sfxValueAt(consideredProviders, ""),
        ["requestedPlatformCapabilityId"]: sfxValueAt(input, "requestedPlatformCapabilityId"),
        ["requestedTarget"]: sfxValueAt(input, "requestedTarget"),
        ["resolutionType"]: "sidefx-semantic-provider-resolution.v1",
        ["snapshotDigest"]: sfxValueAt(input, "snapshotDigest"),
      };
      const derivedResolutionDigest = sfxFormat("sha256:{digest}", {
        ["digest"]: crypto
          .createHash("sha256")
          .update(String(JSON.stringify(sfxValueAt(resolutionSubject, ""))))
          .digest("hex"),
      });
      return sfxMerge(sfxValueAt(resolutionSubject, ""), {
        ["resolutionDigest"]: sfxValueAt(derivedResolutionDigest, ""),
      });
    })();
  }
}
