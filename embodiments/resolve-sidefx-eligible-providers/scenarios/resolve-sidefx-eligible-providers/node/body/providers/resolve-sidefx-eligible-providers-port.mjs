// Generated from capabilities/resolve-sidefx-eligible-providers/semantic-transformation.authority.json; sha256:27abab599fb60064581bd8ef647a054059d157a4659503178a679e96169ff89d
import { crypto } from "./native-mechanics.mjs";
export class ResolveSidefxEligibleProvidersPort {
  execute(input, root = input) {
    return (() => {
      const consideredProviders = (input?.providerBindings).map((binding, bindingIndex) =>
        (() => {
          const capabilityMatches =
            binding?.platformCapabilityId === input?.requestedPlatformCapabilityId;
          const isAdmitted = binding?.lifecycle === "ADMITTED";
          const conformanceIsAdmitted = (input?.conformantDispositions).includes(
            binding?.conformanceDisposition,
          );
          const targetIsDeclared = (binding?.declaredTargets).includes(input?.requestedTarget);
          const evaluation = capabilityMatches
            ? isAdmitted
              ? conformanceIsAdmitted
                ? targetIsDeclared
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
            : { ["disposition"]: "NOT_APPLICABLE", ["reasonCode"]: "PLATFORM_CAPABILITY_MISMATCH" };
          return {
            ["authorityBindings"]: binding?.authorityBindings,
            ["conformanceDisposition"]: binding?.conformanceDisposition,
            ["conformanceReceiptDigest"]: binding?.conformanceReceiptDigest,
            ["conformanceReceiptRef"]: binding?.conformanceReceiptRef,
            ["eligibilityDisposition"]: evaluation?.disposition,
            ["lifecycle"]: binding?.lifecycle,
            ["platformCapabilityId"]: binding?.platformCapabilityId,
            ["providerAuthorityDigest"]: binding?.providerAuthorityDigest,
            ["providerAuthorityId"]: binding?.providerAuthorityId,
            ["providerAuthorityRef"]: binding?.providerAuthorityRef,
            ["providerBindingDigest"]: binding?.providerBindingDigest,
            ["providerBindingRef"]: binding?.providerBindingRef,
            ["reasonCode"]: evaluation?.reasonCode,
          };
        })(),
      );
      const eligibleProviders = consideredProviders.filter((provider, providerIndex) =>
        Boolean(provider?.eligibilityDisposition === "ELIGIBLE"),
      );
      const undeclaredTargetProviders = consideredProviders.filter(
        (provider$binding, providerIndex$binding) =>
          Boolean(provider$binding?.reasonCode === "TARGET_NOT_DECLARED_BY_BINDING"),
      );
      const undeclaredTargetFindings = undeclaredTargetProviders.map(
        (provider$binding$binding, providerIndex$binding$binding) => ({
          ["code"]: "PROVIDER_TARGET_NOT_DECLARED",
          ["message"]:
            "Provider authority {id} is admitted and conformant but declares no projection target, so its eligibility for the requested target is not observable.".replaceAll(
              "{id}",
              String(provider$binding$binding?.providerAuthorityId),
            ),
          ["ruleId"]: "sidefx-semantic-provider-eligibility.v1",
          ["severity"]: "WARNING",
          ["sourcePointer"]: "",
          ["sourceRef"]: provider$binding$binding?.providerBindingRef,
        }),
      );
      const resolutionSubject = {
        ["consideredCount"]: consideredProviders.length,
        ["disposition"]: eligibleProviders.length > 0 ? "PROVIDERS_RESOLVED" : "NOT_OBSERVABLE",
        ["eligibleCount"]: eligibleProviders.length,
        ["findings"]: undeclaredTargetFindings,
        ["providers"]: consideredProviders,
        ["requestedPlatformCapabilityId"]: input?.requestedPlatformCapabilityId,
        ["requestedTarget"]: input?.requestedTarget,
        ["resolutionType"]: "sidefx-semantic-provider-resolution.v1",
        ["snapshotDigest"]: input?.snapshotDigest,
      };
      const derivedResolutionDigest = "sha256:{digest}".replaceAll(
        "{digest}",
        String(
          crypto
            .createHash("sha256")
            .update(String(JSON.stringify(resolutionSubject)))
            .digest("hex"),
        ),
      );
      return Object.assign({}, resolutionSubject, {
        ["resolutionDigest"]: derivedResolutionDigest,
      });
    })();
  }
}
