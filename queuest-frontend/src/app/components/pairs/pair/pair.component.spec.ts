import { ComponentFixture, TestBed } from '@angular/core/testing';

import { PairComponent } from './pair.component';

describe('PairComponent', () => {
  let component: PairComponent;
  let fixture: ComponentFixture<PairComponent>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [PairComponent]
    });
    fixture = TestBed.createComponent(PairComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
