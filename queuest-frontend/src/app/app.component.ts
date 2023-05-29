import {Component, OnInit} from '@angular/core';
import {HttpClient} from '@angular/common/http';

class Item {
  name!:string;
  id!:number;
}

@Component({
  selector: 'app-root',
  templateUrl: './app.component.html',
  styleUrls: ['./app.component.scss']
})
export class AppComponent implements OnInit {
  title = 'queuest-frontend';
  public items: Item[] = [];



  constructor(
    private http: HttpClient
  ) {
  }

  ngOnInit(): void {
    this.getShippingPrices().subscribe((value) => this.items = value)

  }

  getShippingPrices() {
    return this.http.get<Item[]>('http://localhost:3001/items');
  }
}
