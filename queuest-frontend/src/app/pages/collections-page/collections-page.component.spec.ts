import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CollectionsPageComponent } from './collections-page.component';

describe('CollectionsComponent', () => {
    let component: CollectionsPageComponent;
    let fixture: ComponentFixture<CollectionsPageComponent>;

    beforeEach(() => {
        TestBed.configureTestingModule({
            declarations: [CollectionsPageComponent],
        });
        fixture = TestBed.createComponent(CollectionsPageComponent);
        component = fixture.componentInstance;
        fixture.detectChanges();
    });

    it('should create', () => {
        expect(component).toBeTruthy();
    });
});
