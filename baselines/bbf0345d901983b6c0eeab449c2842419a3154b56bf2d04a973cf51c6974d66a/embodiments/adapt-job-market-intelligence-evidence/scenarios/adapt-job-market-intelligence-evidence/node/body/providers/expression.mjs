// Resolver-internal object invocation; semantic identities remain in the declaration.
export class Expression {
    constructor(mechanic, parameters, sourcePointer, observe) {
        this.mechanic = mechanic;
        this.parameters = parameters;
        this.sourcePointer = sourcePointer;
        this.observe = observe;
    }
    execute(scope) {
        this.observe?.({ sourcePointer: this.sourcePointer, mechanic: this.mechanic.constructor.name });
        return this.mechanic.execute(this.parameters, scope, (child, nextScope = scope) => child.execute(nextScope));
    }
}
