import { ComponentFixture, TestBed } from '@angular/core/testing';

import { CollectionsSidepanelComponent } from './collections-sidepanel.component';

describe('CollectionsSidepanelComponent', () => {
  let component: CollectionsSidepanelComponent;
  let fixture: ComponentFixture<CollectionsSidepanelComponent>;

  beforeEach(() => {
    TestBed.configureTestingModule({
      declarations: [CollectionsSidepanelComponent]
    });
    fixture = TestBed.createComponent(CollectionsSidepanelComponent);
    component = fixture.componentInstance;
    fixture.detectChanges();
  });

  it('should create', () => {
    expect(component).toBeTruthy();
  });
});
