// Render the capability's canonical story as review-ready Markdown.
//
// Same rule as the plain narrator: this composes headings, tables and diagram
// layout only. Every fact is a value read from the estate model. Absent
// authority is stated as absent and never replaced with plausible text.
//
// Two things this renderer deliberately refuses to smooth over, because both are
// real conditions of the selected model and both matter to a reviewer:
//
//   * one declared id may have several retained definitions, and they may
//     disagree. Every definition is shown as it is; none are merged into a union.
//   * an execution authority may declare an invocation of a scenario the model
//     does not resolve into the closure. That disagreement is reported.
//
// The invocation tree is drawn from the scenario invocations the model declares
// as relationships, never from an ordering guessed out of closure depth.
const ABSENT = '_(not declared)_';
const PLAIN = '(not declared)';
const has = text => typeof text === 'string' && text.trim().length > 0;
const value = text => (has(text) ? text : ABSENT);
const plain = text => (has(text) ? text : PLAIN);
// Markdown table cells cannot carry a raw pipe or newline.
const cell = text => (has(text) ? text.replace(/\|/g, '\\|').replace(/\s*\n\s*/g, ' ') : ABSENT);
const fence = (lines, language = 'text') => ['```' + language, ...lines, '```'];
const short = digest => (typeof digest === 'string' ? digest.replace(/^sha256:/, '').slice(0, 12) : PLAIN);

function table(headers, rows) {
  if (!rows.length) return [];
  return [`| ${headers.join(' | ')} |`, `| ${headers.map(() => '---').join(' | ')} |`,
    ...rows.map(row => `| ${row.map(cell).join(' | ')} |`)];
}

function distinct(definitions, field) {
  return [...new Set(definitions.map(definition => definition[field]).filter(item => item !== null && item !== undefined))].sort();
}

// A real tree over declared edges. Repeated and cyclic targets are marked where
// they recur instead of being expanded again.
function invocationTree(rootId, scenarios, invocations) {
  const children = new Map();
  for (const edge of invocations) {
    if (!children.has(edge.fromScenarioId)) children.set(edge.fromScenarioId, []);
    children.get(edge.fromScenarioId).push(edge.toScenarioId);
  }
  for (const list of children.values()) list.sort();
  const lines = [];
  const expanded = new Set();
  const walk = (id, prefix, last, root) => {
    const seen = expanded.has(id);
    lines.push(root ? id : `${prefix}${last ? '`-- ' : '|-- '}${id}${seen ? '  (shown above)' : ''}`);
    if (seen) return;
    expanded.add(id);
    const kids = children.get(id) ?? [];
    const next = root ? '' : prefix + (last ? '    ' : '|   ');
    kids.forEach((kid, index) => walk(kid, next, index === kids.length - 1, false));
  };
  walk(rootId, '', true, true);
  return { lines, unreached: scenarios.map(scenario => scenario.scenarioId).filter(id => !expanded.has(id)) };
}

function operationSketch(definition, portsById, inClosure, unresolved) {
  const lines = [];
  if (!definition.operations.length) lines.push(`\`-- operations: ${PLAIN}`);
  definition.operations.forEach((operation, index) => {
    const last = index === definition.operations.length - 1;
    const target = operation.portId ?? operation.scenarioId ?? null;
    const missing = operation.kind === 'invoke-scenario' && operation.scenarioId && !inClosure.has(operation.scenarioId);
    if (missing && !unresolved.includes(operation.scenarioId)) unresolved.push(operation.scenarioId);
    lines.push(`${last ? '`--' : '|--'} ${plain(operation.kind)}${target ? ` --> ${target}` : ''}${missing ? '   (not in the declared closure)' : ''}`);
    const stem = last ? '    ' : '|   ';
    const port = operation.portId ? portsById.get(operation.portId) : undefined;
    if (operation.portId && !port) lines.push(`${stem}\`-- port definition: ${PLAIN}`);
    if (port) {
      lines.push(`${stem}|-- platform capability: ${distinct(port.definitions, 'platformCapabilityId').join(', ') || PLAIN}`);
      lines.push(`${stem}\`-- transformation: ${distinct(port.definitions, 'transformationId').join(', ') || PLAIN}`);
    }
  });
  return lines;
}

function scenarioSection(scenario, lines) {
  const specified = scenario.definitions.find(definition => definition.specification) ?? null;
  lines.push(`### ${specified?.specification.name ?? scenario.scenarioId}`, '');
  lines.push(...table(['Field', 'Value'], [
    ['Scenario', `\`${scenario.scenarioId}\``],
    ['Depth', scenario.minimumDepth === 0 ? '0 (the scenario read)' : String(scenario.minimumDepth)],
    ...(scenario.cycleDetected ? [['Cycle', 'declared']] : []),
    ['Retained definitions', String(scenario.definitions.length)],
  ]));
  lines.push('');
  if (!scenario.definitions.length) {
    lines.push('This scenario is named by the declared closure; the estate retains no definition for it.', '');
    return;
  }
  const labelled = scenario.definitions.length > 1;
  if (labelled) lines.push(`The model retains ${scenario.definitions.length} definitions for this scenario. Each is shown as retained.`, '');
  for (const definition of scenario.definitions) {
    if (labelled) lines.push(`**Definition \`${short(definition.definitionDigest)}\`**`, '');
    if (definition.specification) {
      const specification = definition.specification;
      if (specification.description) lines.push(specification.description, '');
      if (specification.steps.length) {
        // The steps are authored prose in the authority and are reproduced verbatim.
        lines.push(...fence([`${specification.keyword ?? 'Scenario'}: ${specification.name ?? scenario.scenarioId}`,
          ...specification.steps.map(step => `  ${(step.keyword ?? '').trim()} ${step.text ?? ''}`.trimEnd())], 'gherkin'), '');
      } else {
        lines.push(`Steps: ${ABSENT}`, '');
      }
      if (specification.tags.length) lines.push(`Tags: ${specification.tags.map(tag => `\`${tag}\``).join(', ')}`, '');
      if (specification.examples.length) lines.push(`Examples declared: ${specification.examples.length}`, '');
    } else if (definition.face) {
      // A face is a different declaration from an authored specification, not a
      // missing one, and is reported as what it is.
      lines.push('This definition declares the scenario\'s face rather than an authored specification.', '');
      lines.push(...table(['Face', 'Declared'], [
        ['Event', definition.face.event], ['Input', definition.face.input], ['Outcome', definition.face.outcome],
      ]), '');
    } else {
      lines.push(`This definition declares neither an authored specification nor a face. ${ABSENT}`, '');
    }
  }
}

export function narrateCapabilityMarkdown(meaning) {
  const { capability, scenarios, executionAuthorities, ports, transformations,
    observableConditions, invocations, mechanics, providers } = meaning;
  const lines = [];

  lines.push(`# ${capability.capabilityId}`, '');
  if (has(capability.userStory?.intent)) lines.push(`> ${capability.userStory.intent}`, '');

  lines.push('## Identity', '');
  lines.push(...table(['Field', 'Value'], [
    ['Capability', capability.capabilityId],
    ['Namespace', capability.namespaceId],
    ['Mode', capability.mode],
    ['Declared root scenario', capability.declaredRootCount === 1
      ? capability.declaredRootScenarioId : `(not declared: ${capability.declaredRootCount} declared root scenarios)`],
    ...(capability.selectedScenarioId === capability.declaredRootScenarioId
      ? [] : [['Scenario read', capability.selectedScenarioId]]),
    ['Definition digest', `\`${capability.definitionDigest}\``],
    ['Snapshot', `\`${meaning.snapshotId}\``],
    ['Projection', `\`${meaning.projectionDigest}\``],
  ]));
  lines.push('');

  lines.push('## User story', '');
  if (capability.userStory) {
    lines.push(...table(['Field', 'Declared'], [
      ['Actor', capability.userStory.actor],
      ['Intent', capability.userStory.intent],
      ['Outcome', capability.userStory.outcome],
    ]), '');
  } else {
    lines.push(`The estate declares no user story for this capability. ${ABSENT}`, '');
  }

  lines.push('## Experience', '');
  if (capability.experience) {
    lines.push(...table(['Field', 'Declared'], [
      ['Actor', capability.experience.actor],
      ['Experience', capability.experience.experienceId],
      ['Promise', capability.experience.promise],
    ]), '');
  } else {
    lines.push(`The estate declares no experience for this capability. ${ABSENT}`, '');
  }

  lines.push(`## Observable conditions (${observableConditions.length})`, '');
  if (observableConditions.length) {
    // The estate retains an identity for each condition and no prose, so the
    // identities are listed exactly as retained.
    for (const condition of observableConditions) lines.push(`- \`${condition.conditionId}\``);
  } else {
    lines.push(`No observable condition is declared against this capability definition. ${ABSENT}`);
  }
  lines.push('');

  lines.push(`## Scenario closure (${scenarios.length})`, '');
  const tree = invocationTree(capability.selectedScenarioId, scenarios, invocations);
  lines.push(`Drawn from the ${invocations.length} scenario ${invocations.length === 1 ? 'invocation' : 'invocations'} the model declares as relationships.`, '');
  lines.push(...fence(tree.lines), '');
  if (tree.unreached.length) {
    lines.push(`${tree.unreached.length === 1 ? 'This scenario is' : 'These scenarios are'} in the declared closure, but no declared invocation edge reaches ${tree.unreached.length === 1 ? 'it' : 'them'} from the scenario read:`, '');
    for (const id of tree.unreached) lines.push(`- \`${id}\``);
    lines.push('');
  }

  lines.push('## Scenarios', '');
  for (const scenario of scenarios) scenarioSection(scenario, lines);

  lines.push(`## Execution plan (${executionAuthorities.length} declared execution ${executionAuthorities.length === 1 ? 'authority' : 'authorities'})`, '');
  if (!executionAuthorities.length) {
    lines.push(`No execution authority is declared for the scenarios in this closure. ${ABSENT}`, '');
  }
  const portsById = new Map(ports.map(port => [port.portId, port]));
  const inClosure = new Set(scenarios.map(scenario => scenario.scenarioId));
  const unresolved = [];
  for (const authority of executionAuthorities) {
    const shapes = new Set(authority.definitions.map(definition => JSON.stringify(definition.operations)));
    lines.push(`### \`${authority.authorityId}\``, '');
    lines.push(...table(['Field', 'Value'], [
      ['Owning scenario', distinct(authority.definitions, 'owningScenarioId').join(', ')],
      ['Retained definitions', String(authority.definitions.length)],
      ...(authority.definitions.length > 1
        ? [['Agreement', shapes.size === 1 ? 'all declare the same operations'
          : `**they declare ${shapes.size} different operation sets**`]] : []),
    ]));
    lines.push('');
    for (const definition of authority.definitions) {
      const head = authority.definitions.length === 1
        ? authority.authorityId : `${authority.authorityId}   (definition ${short(definition.definitionDigest)})`;
      lines.push(...fence([head, ...operationSketch(definition, portsById, inClosure, unresolved)]), '');
    }
  }

  if (unresolved.length) {
    lines.push(`## Declared scenario invocations not in the closure (${unresolved.length})`, '');
    lines.push('An execution authority declares an invocation of these scenarios, but the selected',
      'estate model does not resolve them into this capability\'s closure. Both statements are',
      'retained authority; they disagree.', '');
    for (const id of unresolved.sort()) lines.push(`- \`${id}\``);
    lines.push('');
  }

  lines.push(`## Transformations (${transformations.length})`, '');
  if (!transformations.length) {
    lines.push(`No transformation is configured by these ports. ${ABSENT}`, '');
  } else {
    lines.push(...table(['Transformation', 'Retained definitions', 'Declared expression keys'],
      transformations.map(transformation => [
        `\`${transformation.transformationId}\``,
        String(transformation.definitions.length),
        [...new Set(transformation.definitions.flatMap(definition => definition.expressionKeys ?? []))].sort().join(', '),
      ])), '');
  }

  lines.push(`## Mechanics (${mechanics.length})`, '');
  if (!mechanics.length) {
    lines.push(`No provider declares a mechanic implementation for these platform capabilities. ${ABSENT}`, '');
  } else {
    lines.push(`${providers.length} ${providers.length === 1 ? 'provider declares' : 'providers declare'} an implementation of these ports' platform capabilities.`, '');
    lines.push(...table(['Provider', 'Mechanic', 'Definition profile', 'Via platform capability'],
      mechanics.map(mechanic => [`\`${mechanic.providerId}\``, `\`${mechanic.mechanicId}\``,
        mechanic.definitionProfile, `\`${mechanic.platformCapabilityId}\``])), '');
  }

  lines.push('---', '');
  lines.push(`Read from snapshot \`${meaning.snapshotId}\`, projection \`${meaning.projectionDigest}\`.`);
  lines.push('Every value above is retained estate authority; nothing is inferred or supplied by the renderer.');
  return lines;
}
