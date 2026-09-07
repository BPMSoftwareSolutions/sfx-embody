// Generated from capabilities/resolve-sidefx-eligible-providers/semantic-transformation.authority.json; sha256:27abab599fb60064581bd8ef647a054059d157a4659503178a679e96169ff89d
import { Expression } from './expression.mjs';
import { createMechanics } from './mechanics.mjs';
export class ResolveSidefxEligibleProvidersPort {
    constructor(mechanics = createMechanics(), observe) {
        const expression0 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "providerBindings" }, "/bindings/consideredProviders/from", observe);
        const expression1 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "platformCapabilityId" }, "/bindings/consideredProviders/value/bindings/capabilityMatches/left", observe);
        const expression2 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "requestedPlatformCapabilityId" }, "/bindings/consideredProviders/value/bindings/capabilityMatches/right", observe);
        const expression3 = new Expression(mechanics["equals"], { ["left"]: expression1, ["right"]: expression2 }, "/bindings/consideredProviders/value/bindings/capabilityMatches", observe);
        const expression4 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "lifecycle" }, "/bindings/consideredProviders/value/bindings/isAdmitted/left", observe);
        const expression5 = new Expression(mechanics["literal"], { ["value"]: "ADMITTED" }, "/bindings/consideredProviders/value/bindings/isAdmitted/right", observe);
        const expression6 = new Expression(mechanics["equals"], { ["left"]: expression4, ["right"]: expression5 }, "/bindings/consideredProviders/value/bindings/isAdmitted", observe);
        const expression7 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "conformantDispositions" }, "/bindings/consideredProviders/value/bindings/conformanceIsAdmitted/in", observe);
        const expression8 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "conformanceDisposition" }, "/bindings/consideredProviders/value/bindings/conformanceIsAdmitted/value", observe);
        const expression9 = new Expression(mechanics["includes"], { ["in"]: expression7, ["value"]: expression8 }, "/bindings/consideredProviders/value/bindings/conformanceIsAdmitted", observe);
        const expression10 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "declaredTargets" }, "/bindings/consideredProviders/value/bindings/targetIsDeclared/in", observe);
        const expression11 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "requestedTarget" }, "/bindings/consideredProviders/value/bindings/targetIsDeclared/value", observe);
        const expression12 = new Expression(mechanics["includes"], { ["in"]: expression10, ["value"]: expression11 }, "/bindings/consideredProviders/value/bindings/targetIsDeclared", observe);
        const expression13 = new Expression(mechanics["path"], { ["from"]: "capabilityMatches", ["path"]: "" }, "/bindings/consideredProviders/value/bindings/evaluation/when", observe);
        const expression14 = new Expression(mechanics["path"], { ["from"]: "isAdmitted", ["path"]: "" }, "/bindings/consideredProviders/value/bindings/evaluation/then/when", observe);
        const expression15 = new Expression(mechanics["path"], { ["from"]: "conformanceIsAdmitted", ["path"]: "" }, "/bindings/consideredProviders/value/bindings/evaluation/then/then/when", observe);
        const expression16 = new Expression(mechanics["path"], { ["from"]: "targetIsDeclared", ["path"]: "" }, "/bindings/consideredProviders/value/bindings/evaluation/then/then/then/when", observe);
        const expression17 = new Expression(mechanics["literal"], { ["value"]: "ELIGIBLE" }, "/bindings/consideredProviders/value/bindings/evaluation/then/then/then/then/fields/disposition", observe);
        const expression18 = new Expression(mechanics["literal"], { ["value"]: "ADMITTED_CONFORMANT_AND_TARGET_DECLARED" }, "/bindings/consideredProviders/value/bindings/evaluation/then/then/then/then/fields/reasonCode", observe);
        const expression19 = new Expression(mechanics["object"], { ["fields"]: {
                ["disposition"]: expression17,
                ["reasonCode"]: expression18
            } }, "/bindings/consideredProviders/value/bindings/evaluation/then/then/then/then", observe);
        const expression20 = new Expression(mechanics["literal"], { ["value"]: "NOT_OBSERVABLE" }, "/bindings/consideredProviders/value/bindings/evaluation/then/then/then/else/fields/disposition", observe);
        const expression21 = new Expression(mechanics["literal"], { ["value"]: "TARGET_NOT_DECLARED_BY_BINDING" }, "/bindings/consideredProviders/value/bindings/evaluation/then/then/then/else/fields/reasonCode", observe);
        const expression22 = new Expression(mechanics["object"], { ["fields"]: {
                ["disposition"]: expression20,
                ["reasonCode"]: expression21
            } }, "/bindings/consideredProviders/value/bindings/evaluation/then/then/then/else", observe);
        const expression23 = new Expression(mechanics["if"], { ["when"]: expression16, ["then"]: expression19, ["else"]: expression22 }, "/bindings/consideredProviders/value/bindings/evaluation/then/then/then", observe);
        const expression24 = new Expression(mechanics["literal"], { ["value"]: "NOT_OBSERVABLE" }, "/bindings/consideredProviders/value/bindings/evaluation/then/then/else/fields/disposition", observe);
        const expression25 = new Expression(mechanics["literal"], { ["value"]: "CONFORMANCE_EVIDENCE_ABSENT" }, "/bindings/consideredProviders/value/bindings/evaluation/then/then/else/fields/reasonCode", observe);
        const expression26 = new Expression(mechanics["object"], { ["fields"]: {
                ["disposition"]: expression24,
                ["reasonCode"]: expression25
            } }, "/bindings/consideredProviders/value/bindings/evaluation/then/then/else", observe);
        const expression27 = new Expression(mechanics["if"], { ["when"]: expression15, ["then"]: expression23, ["else"]: expression26 }, "/bindings/consideredProviders/value/bindings/evaluation/then/then", observe);
        const expression28 = new Expression(mechanics["literal"], { ["value"]: "INELIGIBLE" }, "/bindings/consideredProviders/value/bindings/evaluation/then/else/fields/disposition", observe);
        const expression29 = new Expression(mechanics["literal"], { ["value"]: "PROVIDER_NOT_ADMITTED" }, "/bindings/consideredProviders/value/bindings/evaluation/then/else/fields/reasonCode", observe);
        const expression30 = new Expression(mechanics["object"], { ["fields"]: {
                ["disposition"]: expression28,
                ["reasonCode"]: expression29
            } }, "/bindings/consideredProviders/value/bindings/evaluation/then/else", observe);
        const expression31 = new Expression(mechanics["if"], { ["when"]: expression14, ["then"]: expression27, ["else"]: expression30 }, "/bindings/consideredProviders/value/bindings/evaluation/then", observe);
        const expression32 = new Expression(mechanics["literal"], { ["value"]: "NOT_APPLICABLE" }, "/bindings/consideredProviders/value/bindings/evaluation/else/fields/disposition", observe);
        const expression33 = new Expression(mechanics["literal"], { ["value"]: "PLATFORM_CAPABILITY_MISMATCH" }, "/bindings/consideredProviders/value/bindings/evaluation/else/fields/reasonCode", observe);
        const expression34 = new Expression(mechanics["object"], { ["fields"]: {
                ["disposition"]: expression32,
                ["reasonCode"]: expression33
            } }, "/bindings/consideredProviders/value/bindings/evaluation/else", observe);
        const expression35 = new Expression(mechanics["if"], { ["when"]: expression13, ["then"]: expression31, ["else"]: expression34 }, "/bindings/consideredProviders/value/bindings/evaluation", observe);
        const expression36 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "authorityBindings" }, "/bindings/consideredProviders/value/value/fields/authorityBindings", observe);
        const expression37 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "conformanceDisposition" }, "/bindings/consideredProviders/value/value/fields/conformanceDisposition", observe);
        const expression38 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "conformanceReceiptDigest" }, "/bindings/consideredProviders/value/value/fields/conformanceReceiptDigest", observe);
        const expression39 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "conformanceReceiptRef" }, "/bindings/consideredProviders/value/value/fields/conformanceReceiptRef", observe);
        const expression40 = new Expression(mechanics["path"], { ["from"]: "evaluation", ["path"]: "disposition" }, "/bindings/consideredProviders/value/value/fields/eligibilityDisposition", observe);
        const expression41 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "lifecycle" }, "/bindings/consideredProviders/value/value/fields/lifecycle", observe);
        const expression42 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "platformCapabilityId" }, "/bindings/consideredProviders/value/value/fields/platformCapabilityId", observe);
        const expression43 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "providerAuthorityDigest" }, "/bindings/consideredProviders/value/value/fields/providerAuthorityDigest", observe);
        const expression44 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "providerAuthorityId" }, "/bindings/consideredProviders/value/value/fields/providerAuthorityId", observe);
        const expression45 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "providerAuthorityRef" }, "/bindings/consideredProviders/value/value/fields/providerAuthorityRef", observe);
        const expression46 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "providerBindingDigest" }, "/bindings/consideredProviders/value/value/fields/providerBindingDigest", observe);
        const expression47 = new Expression(mechanics["path"], { ["from"]: "binding", ["path"]: "providerBindingRef" }, "/bindings/consideredProviders/value/value/fields/providerBindingRef", observe);
        const expression48 = new Expression(mechanics["path"], { ["from"]: "evaluation", ["path"]: "reasonCode" }, "/bindings/consideredProviders/value/value/fields/reasonCode", observe);
        const expression49 = new Expression(mechanics["object"], { ["fields"]: {
                ["authorityBindings"]: expression36,
                ["conformanceDisposition"]: expression37,
                ["conformanceReceiptDigest"]: expression38,
                ["conformanceReceiptRef"]: expression39,
                ["eligibilityDisposition"]: expression40,
                ["lifecycle"]: expression41,
                ["platformCapabilityId"]: expression42,
                ["providerAuthorityDigest"]: expression43,
                ["providerAuthorityId"]: expression44,
                ["providerAuthorityRef"]: expression45,
                ["providerBindingDigest"]: expression46,
                ["providerBindingRef"]: expression47,
                ["reasonCode"]: expression48
            } }, "/bindings/consideredProviders/value/value", observe);
        const expression50 = new Expression(mechanics["let"], { ["bindings"]: {
                ["capabilityMatches"]: expression3,
                ["isAdmitted"]: expression6,
                ["conformanceIsAdmitted"]: expression9,
                ["targetIsDeclared"]: expression12,
                ["evaluation"]: expression35
            }, ["value"]: expression49 }, "/bindings/consideredProviders/value", observe);
        const expression51 = new Expression(mechanics["map"], { ["from"]: expression0, ["as"]: "binding", ["value"]: expression50 }, "/bindings/consideredProviders", observe);
        const expression52 = new Expression(mechanics["path"], { ["from"]: "consideredProviders", ["path"]: "" }, "/bindings/eligibleProviders/from", observe);
        const expression53 = new Expression(mechanics["path"], { ["from"]: "provider", ["path"]: "eligibilityDisposition" }, "/bindings/eligibleProviders/where/left", observe);
        const expression54 = new Expression(mechanics["literal"], { ["value"]: "ELIGIBLE" }, "/bindings/eligibleProviders/where/right", observe);
        const expression55 = new Expression(mechanics["equals"], { ["left"]: expression53, ["right"]: expression54 }, "/bindings/eligibleProviders/where", observe);
        const expression56 = new Expression(mechanics["filter"], { ["from"]: expression52, ["as"]: "provider", ["where"]: expression55 }, "/bindings/eligibleProviders", observe);
        const expression57 = new Expression(mechanics["path"], { ["from"]: "consideredProviders", ["path"]: "" }, "/bindings/undeclaredTargetProviders/from", observe);
        const expression58 = new Expression(mechanics["path"], { ["from"]: "provider", ["path"]: "reasonCode" }, "/bindings/undeclaredTargetProviders/where/left", observe);
        const expression59 = new Expression(mechanics["literal"], { ["value"]: "TARGET_NOT_DECLARED_BY_BINDING" }, "/bindings/undeclaredTargetProviders/where/right", observe);
        const expression60 = new Expression(mechanics["equals"], { ["left"]: expression58, ["right"]: expression59 }, "/bindings/undeclaredTargetProviders/where", observe);
        const expression61 = new Expression(mechanics["filter"], { ["from"]: expression57, ["as"]: "provider", ["where"]: expression60 }, "/bindings/undeclaredTargetProviders", observe);
        const expression62 = new Expression(mechanics["path"], { ["from"]: "undeclaredTargetProviders", ["path"]: "" }, "/bindings/undeclaredTargetFindings/from", observe);
        const expression63 = new Expression(mechanics["literal"], { ["value"]: "PROVIDER_TARGET_NOT_DECLARED" }, "/bindings/undeclaredTargetFindings/value/fields/code", observe);
        const expression64 = new Expression(mechanics["path"], { ["from"]: "provider", ["path"]: "providerAuthorityId" }, "/bindings/undeclaredTargetFindings/value/fields/message/values/id", observe);
        const expression65 = new Expression(mechanics["format"], { ["template"]: "Provider authority {id} is admitted and conformant but declares no projection target, so its eligibility for the requested target is not observable.", ["values"]: {
                ["id"]: expression64
            } }, "/bindings/undeclaredTargetFindings/value/fields/message", observe);
        const expression66 = new Expression(mechanics["literal"], { ["value"]: "sidefx-semantic-provider-eligibility.v1" }, "/bindings/undeclaredTargetFindings/value/fields/ruleId", observe);
        const expression67 = new Expression(mechanics["literal"], { ["value"]: "WARNING" }, "/bindings/undeclaredTargetFindings/value/fields/severity", observe);
        const expression68 = new Expression(mechanics["literal"], { ["value"]: "" }, "/bindings/undeclaredTargetFindings/value/fields/sourcePointer", observe);
        const expression69 = new Expression(mechanics["path"], { ["from"]: "provider", ["path"]: "providerBindingRef" }, "/bindings/undeclaredTargetFindings/value/fields/sourceRef", observe);
        const expression70 = new Expression(mechanics["object"], { ["fields"]: {
                ["code"]: expression63,
                ["message"]: expression65,
                ["ruleId"]: expression66,
                ["severity"]: expression67,
                ["sourcePointer"]: expression68,
                ["sourceRef"]: expression69
            } }, "/bindings/undeclaredTargetFindings/value", observe);
        const expression71 = new Expression(mechanics["map"], { ["from"]: expression62, ["as"]: "provider", ["value"]: expression70 }, "/bindings/undeclaredTargetFindings", observe);
        const expression72 = new Expression(mechanics["path"], { ["from"]: "consideredProviders", ["path"]: "" }, "/bindings/resolutionSubject/fields/consideredCount/value", observe);
        const expression73 = new Expression(mechanics["length"], { ["value"]: expression72 }, "/bindings/resolutionSubject/fields/consideredCount", observe);
        const expression74 = new Expression(mechanics["path"], { ["from"]: "eligibleProviders", ["path"]: "" }, "/bindings/resolutionSubject/fields/disposition/when/left/value", observe);
        const expression75 = new Expression(mechanics["length"], { ["value"]: expression74 }, "/bindings/resolutionSubject/fields/disposition/when/left", observe);
        const expression76 = new Expression(mechanics["literal"], { ["value"]: 0 }, "/bindings/resolutionSubject/fields/disposition/when/right", observe);
        const expression77 = new Expression(mechanics["greater-than"], { ["left"]: expression75, ["right"]: expression76 }, "/bindings/resolutionSubject/fields/disposition/when", observe);
        const expression78 = new Expression(mechanics["literal"], { ["value"]: "PROVIDERS_RESOLVED" }, "/bindings/resolutionSubject/fields/disposition/then", observe);
        const expression79 = new Expression(mechanics["literal"], { ["value"]: "NOT_OBSERVABLE" }, "/bindings/resolutionSubject/fields/disposition/else", observe);
        const expression80 = new Expression(mechanics["if"], { ["when"]: expression77, ["then"]: expression78, ["else"]: expression79 }, "/bindings/resolutionSubject/fields/disposition", observe);
        const expression81 = new Expression(mechanics["path"], { ["from"]: "eligibleProviders", ["path"]: "" }, "/bindings/resolutionSubject/fields/eligibleCount/value", observe);
        const expression82 = new Expression(mechanics["length"], { ["value"]: expression81 }, "/bindings/resolutionSubject/fields/eligibleCount", observe);
        const expression83 = new Expression(mechanics["path"], { ["from"]: "undeclaredTargetFindings", ["path"]: "" }, "/bindings/resolutionSubject/fields/findings", observe);
        const expression84 = new Expression(mechanics["path"], { ["from"]: "consideredProviders", ["path"]: "" }, "/bindings/resolutionSubject/fields/providers", observe);
        const expression85 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "requestedPlatformCapabilityId" }, "/bindings/resolutionSubject/fields/requestedPlatformCapabilityId", observe);
        const expression86 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "requestedTarget" }, "/bindings/resolutionSubject/fields/requestedTarget", observe);
        const expression87 = new Expression(mechanics["literal"], { ["value"]: "sidefx-semantic-provider-resolution.v1" }, "/bindings/resolutionSubject/fields/resolutionType", observe);
        const expression88 = new Expression(mechanics["path"], { ["from"]: "input", ["path"]: "snapshotDigest" }, "/bindings/resolutionSubject/fields/snapshotDigest", observe);
        const expression89 = new Expression(mechanics["object"], { ["fields"]: {
                ["consideredCount"]: expression73,
                ["disposition"]: expression80,
                ["eligibleCount"]: expression82,
                ["findings"]: expression83,
                ["providers"]: expression84,
                ["requestedPlatformCapabilityId"]: expression85,
                ["requestedTarget"]: expression86,
                ["resolutionType"]: expression87,
                ["snapshotDigest"]: expression88
            } }, "/bindings/resolutionSubject", observe);
        const expression90 = new Expression(mechanics["path"], { ["from"]: "resolutionSubject", ["path"]: "" }, "/bindings/derivedResolutionDigest/values/digest/value/value", observe);
        const expression91 = new Expression(mechanics["json-stringify"], { ["value"]: expression90 }, "/bindings/derivedResolutionDigest/values/digest/value", observe);
        const expression92 = new Expression(mechanics["sha256"], { ["value"]: expression91 }, "/bindings/derivedResolutionDigest/values/digest", observe);
        const expression93 = new Expression(mechanics["format"], { ["template"]: "sha256:{digest}", ["values"]: {
                ["digest"]: expression92
            } }, "/bindings/derivedResolutionDigest", observe);
        const expression94 = new Expression(mechanics["path"], { ["from"]: "resolutionSubject", ["path"]: "" }, "/value/values/0", observe);
        const expression95 = new Expression(mechanics["path"], { ["from"]: "derivedResolutionDigest", ["path"]: "" }, "/value/values/1/fields/resolutionDigest", observe);
        const expression96 = new Expression(mechanics["object"], { ["fields"]: {
                ["resolutionDigest"]: expression95
            } }, "/value/values/1", observe);
        const expression97 = new Expression(mechanics["merge"], { ["values"]: [expression94, expression96] }, "/value", observe);
        const expression98 = new Expression(mechanics["let"], { ["bindings"]: {
                ["consideredProviders"]: expression51,
                ["eligibleProviders"]: expression56,
                ["undeclaredTargetProviders"]: expression61,
                ["undeclaredTargetFindings"]: expression71,
                ["resolutionSubject"]: expression89,
                ["derivedResolutionDigest"]: expression93
            }, ["value"]: expression97 }, "", observe);
        this.expression = expression98;
    }
    execute(input, root = input) {
        return this.expression.execute({ input, root });
    }
}
