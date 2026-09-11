// Render the capability's canonical story as human language.
//
// This narrator adds section labels and ordering only. Every fact it prints is a
// value read from the estate model by read-capability-meaning.mjs. Where the
// authority declares nothing, it says so — it never fills a gap with a default,
// an example, a paraphrase or an inferred sentence.
const ABSENT = '(not declared)';
const value = text => (typeof text === 'string' && text.trim().length ? text : ABSENT);
const indent = (lines, pad = '  ') => lines.map(line => (line.length ? pad + line : line));

function field(label, text, width) {
  return `${label.padEnd(width)}  ${value(text)}`;
}

function heading(title) {
  return ['', title, '-'.repeat(title.length)];
}

// Steps carry their own keyword ("Given ", "When ", "Then ") and authored text.
// They are already prose in the authority and are printed verbatim.
function scenarioLines(scenario) {
  const lines = [];
  const title = [scenario.keyword ?? 'Scenario', scenario.name ?? scenario.scenarioId].join(': ');
  lines.push(`${title}${scenario.minimumDepth === 0 ? '  [root]' : `  [depth ${scenario.minimumDepth}]`}${scenario.cycleDetected ? '  [cycle declared]' : ''}`);
  lines.push(`id: ${scenario.scenarioId}`);
  if (!scenario.declared) {
    lines.push('This scenario is named by the declared closure; the estate retains no scenario definition for it.');
    return lines;
  }
  if (scenario.description) lines.push(scenario.description);
  if (scenario.steps.length) {
    for (const step of scenario.steps) lines.push(`  ${(step.keyword ?? '').trim()} ${step.text ?? ''}`.trimEnd());
  } else {
    lines.push(`  steps: ${ABSENT}`);
  }
  if (scenario.examples?.length) lines.push(`  examples declared: ${scenario.examples.length}`);
  return lines;
}

export function narrateCapabilityMeaning(meaning) {
  const { capability, scenarios, executionAuthorities, ports, transformations, observableConditions, mechanics, providers } = meaning;
  const lines = [];

  lines.push(`Capability  ${capability.capabilityId}`);
  lines.push(`Namespace   ${capability.namespaceId}`);
  lines.push(`Mode        ${value(capability.mode)}`);
  // The declared root and the scenario actually read are distinct facts. When a
  // caller selects another scenario, both are reported rather than conflated.
  lines.push(`Root        ${capability.declaredRootCount === 1 ? capability.declaredRootScenarioId
    : `${ABSENT} (${capability.declaredRootCount} declared root scenarios)`}`);
  if (capability.selectedScenarioId !== capability.declaredRootScenarioId) {
    lines.push(`Selected    ${capability.selectedScenarioId}`);
  }
  lines.push(`Definition  ${capability.definitionDigest}`);
  lines.push(`Snapshot    ${meaning.snapshotId}`);

  lines.push(...heading('User story'));
  if (capability.userStory) {
    lines.push(field('Actor', capability.userStory.actor, 8));
    lines.push(field('Intent', capability.userStory.intent, 8));
    lines.push(field('Outcome', capability.userStory.outcome, 8));
  } else {
    lines.push(`The estate declares no user story for this capability. ${ABSENT}`);
  }

  lines.push(...heading('Experience'));
  if (capability.experience) {
    lines.push(field('Actor', capability.experience.actor, 10));
    lines.push(field('Experience', capability.experience.experienceId, 10));
    lines.push(field('Promise', capability.experience.promise, 10));
  } else {
    lines.push(`The estate declares no experience for this capability. ${ABSENT}`);
  }

  lines.push(...heading(`Observable conditions (${observableConditions.length})`));
  if (observableConditions.length) {
    // The estate retains an identity for each condition and no prose. The
    // declared identities are listed exactly as retained.
    for (const condition of observableConditions) lines.push(`  ${condition.conditionId}`);
  } else {
    lines.push(`No observable condition is declared against this capability definition. ${ABSENT}`);
  }

  lines.push(...heading(`Scenarios (${scenarios.length})`));
  for (const scenario of scenarios) {
    lines.push('');
    lines.push(...indent(scenarioLines(scenario)));
  }

  lines.push(...heading(`Execution plan (${executionAuthorities.length} execution ${executionAuthorities.length === 1 ? 'authority' : 'authorities'})`));
  if (!executionAuthorities.length) {
    lines.push(`No execution authority is declared for the scenarios in this closure. ${ABSENT}`);
  }
  const portsById = new Map(ports.map(port => [port.portId, port]));
  for (const authority of executionAuthorities) {
    lines.push('');
    lines.push(`  ${authority.owningScenarioId}`);
    lines.push(`    execution authority  ${authority.authorityId}`);
    if (!authority.operations.length) lines.push(`    operations           ${ABSENT}`);
    for (const operation of authority.operations) {
      const port = operation.portId ? portsById.get(operation.portId) : undefined;
      lines.push(`    operation            ${value(operation.kind)}${operation.portId ? ` -> ${operation.portId}` : ''}`);
      if (operation.portId && !port) lines.push(`      port definition    ${ABSENT}`);
      if (port) {
        lines.push(`      platform capability  ${value(port.platformCapabilityId)}`);
        lines.push(`      transformation       ${value(port.transformationId)}`);
      }
    }
  }

  lines.push(...heading(`Transformations (${transformations.length})`));
  if (!transformations.length) lines.push(`No transformation is configured by these ports. ${ABSENT}`);
  for (const transformation of transformations) {
    // The expression tree is the mechanics of the transformation. Its declared
    // root operation is reported; the full tree stays in the structured result.
    const root = transformation.expression && typeof transformation.expression === 'object'
      ? Object.keys(transformation.expression).sort().join(', ') : null;
    lines.push(`  ${transformation.transformationId}`);
    lines.push(`    declared expression keys  ${value(root)}`);
  }

  lines.push(...heading(`Mechanics (${mechanics.length} declared provider/mechanic ${mechanics.length === 1 ? 'pair' : 'pairs'})`));
  if (!mechanics.length) {
    lines.push(`No provider declares a mechanic implementation for these platform capabilities. ${ABSENT}`);
  } else {
    lines.push(`Providers declaring an implementation of these ports' platform capabilities: ${providers.length}`);
    for (const provider of providers) {
      lines.push('');
      lines.push(`  ${provider}`);
      for (const mechanic of mechanics.filter(item => item.providerId === provider)) {
        lines.push(`    ${mechanic.mechanicId}  (${value(mechanic.definitionProfile)}, via ${mechanic.platformCapabilityId})`);
      }
    }
  }

  return lines;
}
