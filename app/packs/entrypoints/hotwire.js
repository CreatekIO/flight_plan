import "@hotwired/turbo-rails";
import { Application, Controller } from "@hotwired/stimulus";
import Sortable from "sortablejs";

const stimulus = Application.start();

class SortableController extends Controller {
    static targets = ['draggable', 'ideaIds'];
    static values = { group: String };

    connect(){
      this.sortable = new Sortable(this.element, {
        draggable: '[data-sortable-target=draggable]',
        group: this.groupValue,
        animation: 200
      });
    }

    sort(event) {
        this.ideaIdsTarget.value = this.sortable.toArray().join(',');

        if (!event.target.contains(event.item)) return;

        requestAnimationFrame(() => {
            this.ideaIdsTarget.form.requestSubmit();
        });
    }

 }

 stimulus.register('sortable', SortableController);
