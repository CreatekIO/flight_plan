import "@hotwired/turbo-rails";
import { Application, Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

const stimulus = Application.start();

class SortableController extends Controller {

  static targets = ['draggable']
  static values = { group: String }
    connect(){
      this.sortable = new Sortable(this.element, {
        draggable: '[data-sortable-target=draggable]',
        group: this.groupValue,
        animation: 200
      })
    }

    sort(event) {
        console.log('sort', event, this.sortable.toArray());
    }

 }

 stimulus.register('sortable', SortableController)
