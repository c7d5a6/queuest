import {ChangeDetectionStrategy, Component, EventEmitter, Input, Output} from '@angular/core';
import {
    AbstractControl,
    FormBuilder,
    FormGroup,
    UntypedFormGroup,
    Validators,
} from '@angular/forms';
import { ItemsService } from '../../api/services/items.service';
import { Collection } from '../../api/models/collection';
import { Item } from 'src/app/api/models';
import {DialogRef} from "@ngneat/dialog";
import {Data} from "@angular/router";

@Component({
    selector: 'app-add-item',
    changeDetection: ChangeDetectionStrategy.OnPush,
    templateUrl: './add-item.component.html',
    styleUrls: ['./add-item.component.scss'],
})
export class AddItemComponent {
    collectionId: number | undefined;

    readonly form: FormGroup = this.formBuilder.group({
        name: [null, Validators.required],
    });

    constructor(
        private ref: DialogRef<Data>,
        private formBuilder: FormBuilder,
        private itemService: ItemsService,
    ) {
      if(ref.data['collectionId']){
        this.collectionId = ref.data['collectionId']
      }
    }

    addNewItem(event: any): void {
        this.updateFormValidity(this.form);
        if (!this.form.valid) {
            event.target.blur();
            return;
        }
        const itemEntity: Item = this.form.value;
        itemEntity.calibrated = false;
        if (!this.collectionId) return;
        this.itemService
            .itemsControllerAddItem({
                collectionId: this.collectionId,
                body: itemEntity,
            })
            .subscribe((id) => {
                this.form.reset();
                this.ref.close(id);
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
