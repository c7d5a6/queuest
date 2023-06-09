import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CalibrateItemComponent } from './calibrate-item.component';

describe('CalibrateItemComponent', () => {
  let component: CalibrateItemComponent;
  let fixture: ComponentFixture<CalibrateItemComponent>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [CalibrateItemComponent]
    });
    fixture = TestBed.createComponent(CalibrateItemComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
