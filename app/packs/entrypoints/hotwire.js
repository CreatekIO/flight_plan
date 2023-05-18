import "@hotwired/turbo-rails";
import { Application, Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

const stimulus = Application.start();

class SortableController extends Controller {

  static targets = ['draggable', 'ideaIds']
  static values = { group: String }
    connect(){
      this.sortable = new Sortable(this.element, {
        draggable: '[data-sortable-target=draggable]',
        group: this.groupValue,
        animation: 200
      })
    }

    sort(event) {
        console.log('sort', event, this.sortable.toArray(), this.ideaIdsTarget);
        this.ideaIdsTarget.value = this.sortable.toArray().join(',')
        this.ideaIdsTarget.form.requestSubmit()
        console.log(this.element, this.ideaIdsTarget.form)
    }

 }

 stimulus.register('sortable', SortableController)
