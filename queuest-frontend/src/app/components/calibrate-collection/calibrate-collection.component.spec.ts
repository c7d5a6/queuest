import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CalibrateCollectionComponent } from './calibrate-collection.component';

describe('CalibrateItemComponent', () => {
    let component: CalibrateCollectionComponent;
    let fixture: ComponentFixture<CalibrateCollectionComponent>;

    beforeEach(() => {
        TestBed.configureTestingModule({
            declarations: [CalibrateCollectionComponent],
        });
        fixture = TestBed.createComponent(CalibrateCollectionComponent);
        component = fixture.componentInstance;
        fixture.detectChanges();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
});
