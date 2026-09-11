// Render the capability's canonical story as human language.
//
// This narrator adds section labels and ordering only. Every fact it prints is a
// value read from the estate model by read-capability-meaning.mjs. Where the
// authority declares nothing, it says so — it never fills a gap with a default,
// an example, a paraphrase or an inferred sentence.
//
// The selected model can retain several definitions for one declared id. That is
// reported wherever it happens rather than collapsed to the first one.
const ABSENT = '(not declared)';
const value = text => (typeof text === 'string' && text.trim().length ? text : ABSENT);
const indent = (lines, pad = '  ') => lines.map(line => (line.length ? pad + line : line));
const short = digest => (typeof digest === 'string' ? digest.replace(/^sha256:/, '').slice(0, 12) : ABSENT);

function field(label, text, width) {
  return `${label.padEnd(width)}  ${value(text)}`;
}

function heading(title) {
  return ['', title, '-'.repeat(title.length)];
}

// The distinct declared values of one field across a declared id's definitions.
function distinct(definitions, field) {
  return [...new Set(definitions.map(definition => definition[field]).filter(value => value !== null && value !== undefined))].sort();
}

function retained(count) {
  return count === 1 ? '' : `  [${count} retained definitions; digests differ]`;
}

// Steps carry their own keyword ("Given ", "When ", "Then ") and authored text.
// They are already prose in the authority and are printed verbatim.
function definitionLines(definition, labelled) {
  const body = [];
  if (definition.specification) {
    const specification = definition.specification;
    if (specification.description) body.push(specification.description);
    if (specification.steps.length) {
      for (const step of specification.steps) body.push(`  ${(step.keyword ?? '').trim()} ${step.text ?? ''}`.trimEnd());
    } else {
      body.push(`  steps: ${ABSENT}`);
    }
    if (specification.tags.length) body.push(`  tags: ${specification.tags.join(', ')}`);
    if (specification.examples.length) body.push(`  examples declared: ${specification.examples.length}`);
  } else if (definition.face) {
    // This definition declares the scenario's face rather than an authored
    // specification. It is reported as that, not as a missing scenario.
    body.push("This definition declares the scenario's face, not an authored specification.");
    body.push(`  event    ${value(definition.face.event)}`);
    body.push(`  input    ${value(definition.face.input)}`);
    body.push(`  outcome  ${value(definition.face.outcome)}`);
  } else {
    body.push(`This definition declares neither an authored specification nor a face. ${ABSENT}`);
  }
  return labelled ? [`definition ${short(definition.definitionDigest)}`, ...indent(body)] : body;
}

function scenarioLines(scenario) {
  const lines = [];
  const specified = scenario.definitions.find(definition => definition.specification) ?? null;
  const name = specified?.specification.name ?? scenario.scenarioId;
  const keyword = specified?.specification.keyword ?? 'Scenario';
  lines.push(`${keyword}: ${name}${scenario.minimumDepth === 0 ? '  [the scenario read]' : `  [depth ${scenario.minimumDepth}]`}${scenario.cycleDetected ? '  [cycle declared]' : ''}`);
  lines.push(`id: ${scenario.scenarioId}`);
  if (!scenario.definitions.length) {
    lines.push('This scenario is named by the declared closure; the estate retains no definition for it.');
    return lines;
  }
  lines.push(`retained definitions: ${scenario.definitions.length}${scenario.definitions.length === 1 ? '' : ' (digests differ; each is shown)'}`);
  const labelled = scenario.definitions.length > 1;
  for (const definition of scenario.definitions) lines.push(...definitionLines(definition, labelled));
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

  lines.push(...heading(`Execution plan (${executionAuthorities.length} declared execution ${executionAuthorities.length === 1 ? 'authority' : 'authorities'})`));
  if (!executionAuthorities.length) {
    lines.push(`No execution authority is declared for the scenarios in this closure. ${ABSENT}`);
  }
  const portsById = new Map(ports.map(port => [port.portId, port]));
  const inClosure = new Set(scenarios.map(scenario => scenario.scenarioId));
  const unresolved = [];
  const operationLines = definition => {
    const out = [];
    if (!definition.operations.length) out.push(`operations: ${ABSENT}`);
    for (const operation of definition.operations) {
      const target = operation.portId ?? operation.scenarioId ?? null;
      // A declared invocation of a scenario the closure does not contain is a
      // real disagreement between two declarations. It is reported, not hidden.
      const missing = operation.kind === 'invoke-scenario' && operation.scenarioId && !inClosure.has(operation.scenarioId);
      if (missing && !unresolved.includes(operation.scenarioId)) unresolved.push(operation.scenarioId);
      out.push(`${value(operation.kind)}${target ? ` -> ${target}` : ''}${missing ? '   (not in the declared closure)' : ''}`);
      const port = operation.portId ? portsById.get(operation.portId) : undefined;
      if (operation.portId && !port) out.push(`  port definition: ${ABSENT}`);
      if (port) {
        out.push(`  platform capability  ${distinct(port.definitions, 'platformCapabilityId').join(', ') || ABSENT}`);
        out.push(`  transformation       ${distinct(port.definitions, 'transformationId').join(', ') || ABSENT}`);
      }
    }
    return out;
  };
  for (const authority of executionAuthorities) {
    // Definitions are never merged. Where they disagree, each is shown as it is.
    const shapes = new Set(authority.definitions.map(definition => JSON.stringify(definition.operations)));
    lines.push('');
    lines.push(`  ${authority.authorityId}${authority.definitions.length === 1 ? ''
      : `  [${authority.definitions.length} retained definitions; they declare ${shapes.size === 1 ? 'the same operations' : `${shapes.size} different operation sets`}]`}`);
    lines.push(`    owning scenario  ${distinct(authority.definitions, 'owningScenarioId').join(', ') || ABSENT}`);
    if (authority.definitions.length === 1) {
      lines.push(...indent(operationLines(authority.definitions[0]), '    '));
      continue;
    }
    for (const definition of authority.definitions) {
      lines.push('');
      lines.push(`    definition ${short(definition.definitionDigest)}`);
      lines.push(...indent(operationLines(definition), '      '));
    }
  }
  if (unresolved.length) {
    lines.push(...heading(`Declared scenario invocations not in the closure (${unresolved.length})`));
    lines.push('An execution authority declares an invocation of these scenarios, but the');
    lines.push("selected estate model does not resolve them into this capability's closure:");
    for (const id of unresolved.sort()) lines.push(`  ${id}`);
  }

  lines.push(...heading(`Transformations (${transformations.length})`));
  if (!transformations.length) lines.push(`No transformation is configured by these ports. ${ABSENT}`);
  for (const transformation of transformations) {
    // The expression tree is the mechanics of the transformation. Its declared
    // root keys are reported; the full tree stays in the structured result.
    lines.push(`  ${transformation.transformationId}${retained(transformation.definitions.length)}`);
    const keys = [...new Set(transformation.definitions.flatMap(definition => definition.expressionKeys ?? []))].sort();
    lines.push(`    declared expression keys  ${keys.length ? keys.join(', ') : ABSENT}`);
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
