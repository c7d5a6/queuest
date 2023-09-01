import { Component, EventEmitter, Input, Output } from '@angular/core';
import {
    AbstractControl,
    FormBuilder,
    FormGroup,
    UntypedFormGroup,
    Validators,
} from '@angular/forms';
import { ItemsService } from '../../api/services/items.service';
import { Collection } from '../../api/models/collection';

@Component({
    selector: 'app-add-item',
    templateUrl: './add-item.component.html',
    styleUrls: ['./add-item.component.scss'],
})
export class AddItemComponent {
    @Input() collection!: Collection;
    @Output() changes = new EventEmitter<void>();

    readonly form: FormGroup = this.formBuilder.group({
        name: [null, Validators.required],
    });

    constructor(
        private formBuilder: FormBuilder,
        private itemService: ItemsService,
    ) {}

    addNewItem(event: any): void {
        this.updateFormValidity(this.form);
        if (!this.form.valid) {
            event.target.blur();
            return;
        }
        const itemEntity = this.form.value;
        if (!this.collection.id) return;
        this.itemService
            .itemsControllerAddItem({
                collectionId: this.collection.id,
                body: itemEntity,
            })
            .subscribe(() => {
                this.form.reset();
                this.changes.emit();
            });
    }

    updateFormValidity(form: UntypedFormGroup): void {
        Object.values<AbstractControl>(form.controls).forEach(
            (control: AbstractControl): void => {
                this.updateFormControlValidity(control);
            },
        );
    }

    updateFormControlValidity(control: AbstractControl): void {
        control.markAsTouched();
        control.markAsDirty();
        control.updateValueAndValidity();
    }
}
