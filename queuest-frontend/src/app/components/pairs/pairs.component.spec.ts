import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PairsComponent } from './pairs.component';

describe('PairsComponent', () => {
  let component: PairsComponent;
  let fixture: ComponentFixture<PairsComponent>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [PairsComponent]
    });
    fixture = TestBed.createComponent(PairsComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
