import {ChangeDetectionStrategy, Component, EventEmitter, Input, Output} from '@angular/core';
import {
    AbstractControl,
    FormBuilder,
    FormGroup,
    UntypedFormGroup,
    Validators,
} from '@angular/forms';
import { CollectionsService } from '../../api/services/collections.service';
import { Collection } from '../../api/models/collection';
import { DialogRef } from '@ngneat/dialog';
import { Data } from '@angular/router';

@Component({
    selector: 'app-add-collection',
    changeDetection: ChangeDetectionStrategy.OnPush,
    templateUrl: './add-collection.component.html',
    styleUrls: ['./add-collection.component.scss'],
})
export class AddCollectionComponent {

    readonly form: FormGroup = this.formBuilder.group({
        name: [null, Validators.required],
    });

    constructor(
        private ref: DialogRef<Data>,
        private formBuilder: FormBuilder,
        private collectionsService: CollectionsService,
    ) {}

    addNewItem(event: any): void {
        this.updateFormValidity(this.form);
        if (!this.form.valid) {
            event.target.blur();
            return;
        }
        const newCollection: Collection = this.form.value;
        newCollection.favourite_yn = false;
        this.collectionsService
            .collectionControllerAddCollection({ body: newCollection })
            .subscribe(() => {
                this.form.reset();
                this.ref.close();
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
