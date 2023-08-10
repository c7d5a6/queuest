import { Component } from '@angular/core';
import {Collection} from "../../../api/models/collection";

@Component({
  selector: 'app-collections-sidepanel',
  templateUrl: './collections-sidepanel.component.html',
  styleUrls: ['./collections-sidepanel.component.scss']
})
export class CollectionsSidepanelComponent {

  favCollections: Collection[] = [];

}
